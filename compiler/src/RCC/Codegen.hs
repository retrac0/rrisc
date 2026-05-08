-- | Three-address code → RRISC assembly text (with @%define RCC_*@ prelude).
module RCC.Codegen
  ( codegen
  , CodegenOpts(..)
  , defaultOpts
  ) where

import Control.Monad (when, forM_)
import Control.Monad.State
import Data.Bits ((.&.), shiftR)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import Numeric (showOct)

import qualified RCC.TAC as TAC

-- ---------------------------------------------------------------------------
-- Options

data CodegenOpts = CodegenOpts
  { codeBase :: Int
  , dataBase :: Int
  , stackTop :: Int
  } deriving (Show)

defaultOpts :: CodegenOpts
defaultOpts = CodegenOpts 0o1000 0o3000 0o3000

-- ---------------------------------------------------------------------------
-- Helpers

tshow :: Show a => a -> Text
tshow = T.pack . show

octT :: Int -> Text
octT n = "0o" <> T.pack (showOct n "")

line :: Text -> Text
line t = "    " <> t

-- | Assembly entry symbol for calls emitted from TAC (libc float I/O uses __* names).
asmCalleeName :: Text -> Text
asmCalleeName f
  | f == "atof" = "__atof"
  | f == "ftoa" = "__ftoa"
  | otherwise   = f

-- ---------------------------------------------------------------------------
-- Per-procedure code generation state

data CGState = CGState
  { cgLines    :: [Text]            -- output (reversed)
  , cgSlots    :: Map TAC.Temp Int  -- temp -> slot offset from r6 (after prologue)
  , cgEpiLabel :: TAC.Label
  , cgFuncName :: TAC.Label
  }

type CG = State CGState

emit :: Text -> CG ()
emit t = modify $ \s -> s { cgLines = t : cgLines s }

emitL :: Text -> CG ()
emitL t = emit (line t)

slotOf :: TAC.Temp -> CG Int
slotOf t = do
  m <- gets cgSlots
  case Map.lookup t m of
    Just s  -> pure s
    Nothing -> pure 0   -- shouldn't happen

-- ---------------------------------------------------------------------------
-- Top-level codegen

codegen :: CodegenOpts -> TAC.TACProg -> Text
codegen opts (TAC.TACProg globals procs) = T.unlines $
  prelude
  ++ rwPackedData
  ++ textSectionDecl
  ++ concatMap genProc procs
  ++ rodata
  ++ rwSplitData
  where
    roGlobs = filter TAC.globalConst globals
    rwGlobs = filter (not . TAC.globalConst) globals
    rwWords = sum $ map TAC.globalSize rwGlobs
    -- Code vs RW globals: split layout puts RW after code (separate .section data).
    -- Packed layout puts RW first (.section data) then code (.section text).
    splitMemLayout = not (null rwGlobs) && codeBase opts < dataBase opts
    effectiveCodeBase
      | null rwGlobs   = codeBase opts
      | splitMemLayout = codeBase opts
      | otherwise      = dataBase opts + rwWords

    prelude =
      [ "; rcc-generated assembly"
      , "%define RCC_CODE_BASE " <> octT effectiveCodeBase
      , "%define RCC_DATA_BASE " <> octT (dataBase opts)
      , "%define RCC_STACK_TOP " <> octT (stackTop opts)
      ]

    rwPackedData =
      if null rwGlobs || splitMemLayout
        then []
        else
          "" :
          "    .section data" :
          concatMap genGlobal rwGlobs

    textSectionDecl =
      [ ""
      , "    .section text"
      ]

    rwSplitData =
      if splitMemLayout && not (null rwGlobs)
        then
          "" :
          "    .section data" :
          concatMap genGlobal rwGlobs
        else []

    rodata = if null roGlobs then [] else
      [""] ++ concatMap genGlobal roGlobs

genGlobal :: TAC.Global -> [Text]
genGlobal g =
  [ TAC.globalName g <> ":" ] ++ body
  where
    sz = TAC.globalSize g
    init_ = TAC.globalInit g
    body
      | null init_ = [ line (".fill " <> tshow sz) ]
      | otherwise  =
          [ line (".word " <> T.intercalate ", " (map tshow init_)) ]
          ++ if length init_ < sz
               then [ line (".fill " <> tshow (sz - length init_)) ]
               else []

-- ---------------------------------------------------------------------------
-- Procedure codegen
--
-- Calling convention (must match Arch.md / spec.md §8):
--   r1  — scratch only (not an arg reg); clobbered across calls.
--   r2  — arg 1 / return value
--   r3  — arg 2
--   r4  — arg 3
--   r5  — link register; saved in prologue, restored in epilogue (non-leaf chain).
--   r6  — stack pointer (full descending).
-- Indirect call / branch: load target into r1, then jalr (preserves r2–r4 for args).

genProc :: TAC.Proc -> [Text]
genProc p =
  let temps      = collectTemps p
      (slots, n) = buildSlotMap (TAC.procLocSzs p) temps
      epi     = "_epi_" <> TAC.procName p
      initSt  = CGState [] slots epi (TAC.procName p)
      numStack = max 0 (length (TAC.procParams p) - 3)
      action  = do
        emit ""
        emit ("    .global " <> TAC.procName p)
        emit (TAC.procName p <> ":")
        genPrologue p n
        mapM_ genInstr (TAC.procInstrs p)
        emit (epi <> ":")
        genEpilogue n numStack
  in reverse $ cgLines (execState action initSt)

-- Stack slot assignment order: parameters first, then temps in instruction order.
-- Every temp that appears as a definition *or* as an operand (e.g. ILoad address)
-- must get a slot; otherwise slotOf falls back to 0 and collides with arg slots.
collectTemps :: TAC.Proc -> [TAC.Temp]
collectTemps p =
  let params = TAC.procParams p
      step (seen, acc) instr =
        let ordered = instrDefTemps instr ++ instrOperandTemps instr
            fresh   = filter (`Set.notMember` seen) ordered
            seen'   = foldr Set.insert seen fresh
        in (seen', acc ++ fresh)
      (_, ts) = foldl step (Set.fromList params, params) (TAC.procInstrs p)
  in ts

instrDefTemps :: TAC.Instr -> [TAC.Temp]
instrDefTemps (TAC.IAssign t _)         = [t]
instrDefTemps (TAC.IBinOp  t _ _ _)    = [t]
instrDefTemps (TAC.IUnOp   t _ _)       = [t]
instrDefTemps (TAC.ILoad   t _)         = [t]
instrDefTemps (TAC.ICall (Just t) _ _)  = [t]
instrDefTemps (TAC.IAllocLocal t)       = [t]
instrDefTemps _                         = []

instrOperandTemps :: TAC.Instr -> [TAC.Temp]
instrOperandTemps = concatMap operandLocal . instrOperands

operandLocal :: TAC.Operand -> [TAC.Temp]
operandLocal (TAC.OTemp t)      = [t]
operandLocal (TAC.OLocalAddr t)   = [t]
operandLocal _                  = []

instrOperands :: TAC.Instr -> [TAC.Operand]
instrOperands (TAC.IAssign _ o)       = [o]
instrOperands (TAC.IBinOp _ _ a b)    = [a, b]
instrOperands (TAC.IUnOp _ _ a)       = [a]
instrOperands (TAC.ILoad _ a)        = [a]
instrOperands (TAC.IStore a b)      = [a, b]
instrOperands (TAC.IIfZ o _)          = [o]
instrOperands (TAC.IIfNZ o _)         = [o]
instrOperands (TAC.IIfCmp _ a b _)   = [a, b]
instrOperands (TAC.IIfNCmp _ a b _) = [a, b]
instrOperands (TAC.ICall _ _ args)   = args
instrOperands (TAC.IReturn (Just o)) = [o]
instrOperands _                      = []

-- Build slot map accounting for multi-word locals (arrays/structs).
-- Each temp gets a base slot offset; multi-word locals consume consecutive slots.
buildSlotMap :: Map TAC.Temp Int -> [TAC.Temp] -> (Map TAC.Temp Int, Int)
buildSlotMap locSzs = go 0 []
  where
    go off acc []     = (Map.fromList acc, off)
    go off acc (t:ts) =
      let sz = Map.findWithDefault 1 t locSzs
      in go (off + sz) ((t, off) : acc) ts

-- Prologue: save r5, allocate slots, spill r2–r4 (and stack args) into frame slots.
-- r1–r4 are caller-saved at calls; expression code may use them freely between calls.
genPrologue :: TAC.Proc -> Int -> CG ()
genPrologue p n = do
  -- Save r5
  emitL "subi r6, 1"
  emitL "swr r5, r6"
  -- Allocate slots for all temps (addi unsigned 0..63; subi for decrements)
  when (n > 0) $
    if n <= 63
      then emitL ("subi r6, " <> tshow n)
      else do
        emitLoadConst 1 n
        emitL "sub r6, r6, r1"
  -- Save parameters into their slots: r2/r3/r4 for the first three, stack for the rest.
  -- Stack args were pushed right-to-left by the caller; arg 4 is closest to the frame
  -- (at offset n+1 from r6), arg 5 at n+2, etc.
  forM_ (zip [0..] (TAC.procParams p)) $ \(i, paramName) -> do
    case (i :: Int) of
      0 -> storeRegToTemp 2 paramName
      1 -> storeRegToTemp 3 paramName
      2 -> storeRegToTemp 4 paramName
      _ -> do
        let stackOffset = n + 1 + (i - 3)
        addrOfSlot stackOffset
        emitL "lwr r2, r1"
        storeRegToTemp 2 paramName

genEpilogue :: Int -> Int -> CG ()
genEpilogue n numStack = do
  when (n > 0) $
    if n <= 63
      then emitL ("addi r6, " <> tshow n)
      else do
        emitLoadConst 1 n
        emitL "add r6, r6, r1"
  emitL "lwr r5, r6"
  emitL "addi r6, 1"
  when (numStack > 0) $ emitL ("addi r6, " <> tshow numStack)
  emitL "jalr r0, r5"

-- ---------------------------------------------------------------------------
-- Loading and storing temps

-- Compute (r6 + slot) into r1.
addrOfSlot :: Int -> CG ()
addrOfSlot s
  | s == 0    = emitL "and r1, r6, r7"
  | s <= 63   = do emitL "and r1, r6, r7"
                   emitL ("addi r1, " <> tshow s)
  | otherwise = do emitLoadConst 1 s
                   emitL "add r1, r1, r6"

-- Emit the most compact single instruction that loads constant n into reg.
-- val = n masked to 12 bits.
--   val == 0:              and rx, r0, r0  (1 word)
--   val == 0xFFF (i.e. -1): and rx, r7, r7  (1 word)
--   lower 6 bits zero:     lui rx, val>>6  (1 word, rx not r0/r7)
--   otherwise:             li rx, n        (2 words)
emitLoadConst :: Int -> Int -> CG ()
emitLoadConst reg n =
  let val = n .&. 0xFFF
      rn  = "r" <> tshow reg
  in emitL $ case () of
      _ | val == 0
                   -> "and " <> rn <> ", r0, r0"
        | val == 0xFFF
                   -> "and " <> rn <> ", r7, r7"
        | val .&. 0x3F == 0, reg /= 0, reg /= 7
                   -> "lui " <> rn <> ", " <> tshow (val `shiftR` 6)
        | otherwise
                   -> "li "  <> rn <> ", " <> tshow val

-- Load operand into the given register (2, 3, or 4).
loadOpInto :: Int -> TAC.Operand -> CG ()
loadOpInto reg (TAC.OConst n)  = emitLoadConst reg n
loadOpInto reg (TAC.OAddr lbl) = emitL ("li r" <> tshow reg <> ", " <> lbl)
loadOpInto reg (TAC.OTemp t)   = do
  s <- slotOf t
  addrOfSlot s
  emitL ("lwr r" <> tshow reg <> ", r1")
loadOpInto reg (TAC.OLocalAddr t) = do
  s <- slotOf t
  addrOfSlot s
  when (reg /= 1) $ emitL ("and r" <> tshow reg <> ", r1, r7")

-- Like loadOpInto but adds adj to the slot offset (compensates for r6 drift during arg pushes).
loadOpIntoAdj :: Int -> TAC.Operand -> Int -> CG ()
loadOpIntoAdj reg (TAC.OTemp t) adj = do
  s <- slotOf t
  let s' = s + adj
  addrOfSlot s'
  emitL ("lwr r" <> tshow reg <> ", r1")
loadOpIntoAdj reg (TAC.OLocalAddr t) adj = do
  s <- slotOf t
  let s' = s + adj
  addrOfSlot s'
  when (reg /= 1) $ emitL ("and r" <> tshow reg <> ", r1, r7")
loadOpIntoAdj reg op _ = loadOpInto reg op

storeRegToTemp :: Int -> TAC.Temp -> CG ()
storeRegToTemp reg t = do
  s <- slotOf t
  addrOfSlot s
  emitL ("swr r" <> tshow reg <> ", r1")

-- ---------------------------------------------------------------------------
-- Per-instruction codegen

genInstr :: TAC.Instr -> CG ()
genInstr (TAC.ILabel      lbl) = emit (lbl <> ":")
genInstr (TAC.IComment    txt) = emit (";; " <> txt)
genInstr (TAC.IAllocLocal _  ) = pure ()  -- slot reserved by buildSlotMap; no code needed
genInstr (TAC.IAsmInline  txt) = emitL txt

genInstr (TAC.IAssign t op) = do
  loadOpInto 2 op
  storeRegToTemp 2 t

genInstr (TAC.IBinOp t op a b) = do
  loadOpInto 3 a       -- left in r3
  loadOpInto 2 b       -- right in r2
  emitBinOp op
  storeRegToTemp 2 t

genInstr (TAC.IUnOp t op a) = do
  loadOpInto 2 a
  case op of
    TAC.TNeg  -> emitL "sub r2, r0, r2"          -- r2 = 0 - r2
    TAC.TNot  -> do
      emitL "sub r0, r0, r2"                     -- T = 1 iff r2 != 0
      lTrue <- freshLbl "not_zero"
      lEnd  <- freshLbl "not_end"
      emitL ("bt " <> lTrue)
      emitL "li r2, 1"
      emitL "sub r0, r0, r7"
      emitL ("bt " <> lEnd)
      emit (lTrue <> ":")
      emitL "li r2, 0"
      emit (lEnd <> ":")
    TAC.TBNot -> emitL "sub r2, r7, r2"          -- r2 = -1 - r2 = ~r2
  storeRegToTemp 2 t

genInstr (TAC.ILoad t addr) = do
  loadOpInto 1 addr               -- address in r1
  emitL "lwr r2, r1"              -- r2 = mem[r1]
  storeRegToTemp 2 t

genInstr (TAC.IStore addr val) = do
  loadOpInto 2 val                -- value in r2
  loadOpInto 1 addr               -- address in r1 (doesn't clobber r2)
  emitL "swr r2, r1"              -- mem[r1] = r2

genInstr (TAC.IGoto lbl) = do
  emitL ("li r1, " <> lbl)
  emitL "jalr r0, r1"

genInstr (TAC.IIfCmp op a b lbl) = do
  emitCmpToT op a b >>= \inv ->
    if inv then jumpOnNotT lbl else jumpOnT lbl

genInstr (TAC.IIfNCmp op a b lbl) = do
  emitCmpToT op a b >>= \inv ->
    if inv then jumpOnT lbl else jumpOnNotT lbl

genInstr (TAC.IIfZ op lbl) = do
  -- T=1 iff op!=0; branch when op==0. Assembler relaxes bf if out of ±63 range.
  loadOpInto 2 op
  emitL "sub r0, r0, r2"
  emitL ("bf " <> lbl)

genInstr (TAC.IIfNZ op lbl) = do
  loadOpInto 2 op
  emitL "sub r0, r0, r2"
  emitL ("bt " <> lbl)

genInstr (TAC.ICall mt fname args) = do
  let regArgs   = take 3 args
      stackArgs = drop 3 args
      numStack  = length stackArgs
  -- Push stack args right-to-left; adjust slot offsets as r6 descends.
  forM_ (zip [0..] (reverse stackArgs)) $ \(k, op) -> do
    loadOpIntoAdj 2 op k
    emitL "subi r6, 1"
    emitL "swr r2, r6"
  -- Load register args; r6 is now numStack words below the frame base.
  forM_ (zip [2,3,4] regArgs) $ \(r, op) -> loadOpIntoAdj r op numStack
  -- Issue the call. Callee pops the stack args in its epilogue.
  emitL ("li r1, " <> asmCalleeName fname)
  emitL "jalr r5, r1"
  -- Capture return value if requested.
  case mt of
    Just t  -> storeRegToTemp 2 t
    Nothing -> pure ()

genInstr (TAC.IReturn Nothing) = do
  epi <- gets cgEpiLabel
  emitL ("li r1, " <> epi)
  emitL "jalr r0, r1"

genInstr (TAC.IReturn (Just op)) = do
  loadOpInto 2 op                 -- return value in r2
  epi <- gets cgEpiLabel
  emitL ("li r1, " <> epi)
  emitL "jalr r0, r1"

-- ---------------------------------------------------------------------------
-- Compare helpers for IIfCmp/IIfNCmp

-- Emit compare for (a op b) and set T such that:
-- - For most ops: T=1 means condition is true, return False (not inverted)
-- - For ops where we naturally compute the opposite: return True to indicate inversion
--   (i.e. condition is true when T=0).
emitCmpToT :: TAC.BinOp -> TAC.Operand -> TAC.Operand -> CG Bool
emitCmpToT op a b = do
  loadOpInto 3 a
  loadOpInto 2 b
  case op of
    TAC.TNe -> do
      emitL "sub r1, r3, r2"
      emitL "sub r0, r0, r1"      -- T=1 iff a!=b
      pure False
    TAC.TEq -> do
      emitL "sub r1, r3, r2"
      emitL "sub r0, r0, r1"      -- T=1 iff a!=b (inverted)
      pure True
    TAC.TULt -> do
      emitL "sub r1, r3, r2"      -- T=1 iff a<b unsigned
      pure False
    TAC.TUGt -> do
      emitL "sub r1, r2, r3"      -- T=1 iff b<a
      pure False
    TAC.TULe -> do
      emitL "sub r1, r2, r3"      -- T=1 iff a>b (inverted)
      pure True
    TAC.TUGe -> do
      emitL "sub r1, r3, r2"      -- T=1 iff a<b (inverted)
      pure True
    TAC.TLt -> do
      emitSignedNorm
      emitL "sub r1, r3, r2"      -- T=1 iff a<b signed
      pure False
    TAC.TGt -> do
      emitSignedNorm
      emitL "sub r1, r2, r3"      -- T=1 iff a>b signed
      pure False
    TAC.TLe -> do
      emitSignedNorm
      emitL "sub r1, r2, r3"      -- T=1 iff a>b (inverted)
      pure True
    TAC.TGe -> do
      emitSignedNorm
      emitL "sub r1, r3, r2"      -- T=1 iff a<b (inverted)
      pure True
    _ -> do
      -- Not expected for IIfCmp/IIfNCmp; fall back to boolean materialization path.
      emitBinOp op
      emitL "sub r0, r0, r2"
      pure False

jumpOnT :: TAC.Label -> CG ()
jumpOnT lbl = emitL ("bt " <> lbl)

jumpOnNotT :: TAC.Label -> CG ()
jumpOnNotT lbl = emitL ("bf " <> lbl)

-- ---------------------------------------------------------------------------
-- Binary operation codegen
--
-- Inputs: r3 = left, r2 = right.  Result placed in r2.

emitBinOp :: TAC.BinOp -> CG ()
emitBinOp TAC.TAdd = do
  emitL "add r2, r3, r2"
emitBinOp TAC.TSub = do
  emitL "sub r2, r3, r2"
emitBinOp TAC.TBand = do
  emitL "and r2, r3, r2"
emitBinOp TAC.TBor = do
  -- r3 | r2 = (r3 + r2) - (r3 & r2)
  emitL "and r1, r3, r2"
  emitL "add r2, r3, r2"
  emitL "sub r2, r2, r1"
emitBinOp TAC.TBxor = do
  -- r3 XOR r2 = (r3 | r2) - (r3 & r2) - (r3 & r2)
  emitL "and r1, r3, r2"
  emitL "add r2, r3, r2"
  emitL "sub r2, r2, r1"
  emitL "sub r2, r2, r1"
emitBinOp TAC.TShl  = emitShift True  True   -- logical left
emitBinOp TAC.TShr  = emitShift False False  -- arithmetic right (sign-extending)
emitBinOp TAC.TUShr = emitShift False True   -- logical right (unsigned)
emitBinOp TAC.TMul = do
  emitMul
emitBinOp TAC.TDiv = do
  lDivDone <- freshLbl "div_done"
  lNPos    <- freshLbl "div_npos"
  lDPos    <- freshLbl "div_dpos"
  -- Divide by zero returns 0 (r2=0 already when d=0).
  emitL "sub r0, r0, r2"
  emitL ("bf " <> lDivDone)
  -- Extract and push sign_n.
  emitL "and r1, r3, r7"
  emitL "rol r1, r1"
  emitL "rol r4, r0"
  emitL "subi r6, 1"
  emitL "swr r4, r6"
  -- Extract and push sign_d.
  emitL "and r1, r2, r7"
  emitL "rol r1, r1"
  emitL "rol r4, r0"
  emitL "subi r6, 1"
  emitL "swr r4, r6"
  -- Abs(n): sign_n is at [r6+1].
  emitL "and r1, r6, r7"
  emitL "addi r1, 1"
  emitL "lwr r4, r1"
  emitL "sub r0, r0, r4"
  emitL ("bf " <> lNPos)
  emitL "sub r3, r0, r3"
  emit (lNPos <> ":")
  -- Abs(d): sign_d is at [r6+0].
  emitL "and r1, r6, r7"
  emitL "lwr r4, r1"
  emitL "sub r0, r0, r4"
  emitL ("bf " <> lDPos)
  emitL "sub r2, r0, r2"
  emit (lDPos <> ":")
  emitUDiv                        -- r1=|quotient|, r4=|remainder|
  emitL "and r2, r1, r7"          -- r2 = |quotient|
  -- Pop sign_d into r1.
  emitL "and r1, r6, r7"
  emitL "lwr r1, r1"
  emitL "addi r6, 1"
  -- Pop sign_n into r4.
  emitL "and r4, r6, r7"
  emitL "lwr r4, r4"
  emitL "addi r6, 1"
  -- Negate quotient when exactly one operand was negative (sum==1).
  emitL "add r1, r1, r4"
  emitL "subi r1, 1"
  emitL "sub r0, r0, r1"          -- T=1 iff sum!=1
  emitL ("bt " <> lDivDone)
  emitL "sub r2, r0, r2"
  emit (lDivDone <> ":")
emitBinOp TAC.TMod = do
  lModDone <- freshLbl "mod_done"
  lNPos    <- freshLbl "mod_npos"
  lDPos    <- freshLbl "mod_dpos"
  lRemPos  <- freshLbl "mod_rpos"
  -- Mod by zero returns 0.
  emitL "sub r0, r0, r2"
  emitL ("bf " <> lModDone)
  -- Extract and push sign_n; r4 retains it for the abs(n) test below.
  emitL "and r1, r3, r7"
  emitL "rol r1, r1"
  emitL "rol r4, r0"
  emitL "subi r6, 1"
  emitL "swr r4, r6"
  -- Abs(n): r4 still holds sign_n.
  emitL "sub r0, r0, r4"
  emitL ("bf " <> lNPos)
  emitL "sub r3, r0, r3"
  emit (lNPos <> ":")
  -- Abs(d): use T from sign_d; sign_d not needed later.
  emitL "and r1, r2, r7"
  emitL "rol r1, r1"
  emitL ("bf " <> lDPos)
  emitL "sub r2, r0, r2"
  emit (lDPos <> ":")
  emitUDiv                        -- r1=|quotient|, r4=|remainder|
  -- Pop sign_n into r1.
  emitL "and r1, r6, r7"
  emitL "lwr r1, r1"
  emitL "addi r6, 1"
  -- Negate remainder if n was negative.
  emitL "sub r0, r0, r1"
  emitL ("bf " <> lRemPos)
  emitL "sub r4, r0, r4"
  emit (lRemPos <> ":")
  emitL "and r2, r4, r7"          -- r2 = remainder
  emit (lModDone <> ":")
emitBinOp TAC.TAnd = do
  -- Logical: should not appear (lowered to branches by TAC), but handle anyway.
  emitL "and r2, r3, r2"
emitBinOp TAC.TOr = do
  emitL "and r1, r3, r2"
  emitL "add r2, r3, r2"
  emitL "sub r2, r2, r1"

-- Comparisons: result in r2 as 0 or 1.
emitBinOp TAC.TEq = do
  emitL "sub r1, r3, r2"          -- r1 = a - b
  emitL "sub r0, r0, r1"          -- T = 1 iff (a - b) != 0
  ttoR2 True                      -- r2 = NOT T (1 if equal)
emitBinOp TAC.TNe = do
  emitL "sub r1, r3, r2"
  emitL "sub r0, r0, r1"          -- T = 1 iff a != b
  ttoR2 False                     -- r2 = T
emitBinOp TAC.TLt = do
  emitSignedNorm
  emitL "sub r1, r3, r2"          -- T = 1 iff (a' < b') = (a < b signed)
  ttoR2 False
emitBinOp TAC.TGt = do
  emitSignedNorm
  emitL "sub r1, r2, r3"          -- T = 1 iff b' < a' = a > b
  ttoR2 False
emitBinOp TAC.TLe = do
  emitSignedNorm
  emitL "sub r1, r2, r3"          -- T = 1 iff a > b
  ttoR2 True                      -- r2 = NOT T = a <= b
emitBinOp TAC.TGe = do
  emitSignedNorm
  emitL "sub r1, r3, r2"          -- T = 1 iff a < b
  ttoR2 True                      -- r2 = NOT T = a >= b

-- Unsigned comparisons: borrow flag of 'sub' gives the answer directly.
emitBinOp TAC.TULt = do
  emitL "sub r1, r3, r2"          -- T = 1 iff a < b unsigned
  ttoR2 False
emitBinOp TAC.TUGt = do
  emitL "sub r1, r2, r3"          -- T = 1 iff b < a, i.e., a > b
  ttoR2 False
emitBinOp TAC.TULe = do
  emitL "sub r1, r2, r3"          -- T = 1 iff b < a (a > b)
  ttoR2 True                      -- NOT T = a <= b
emitBinOp TAC.TUGe = do
  emitL "sub r1, r3, r2"          -- T = 1 iff a < b
  ttoR2 True                      -- NOT T = a >= b

-- Add 2048 (sign-bit flip) to both r3 and r2 to convert signed comparison
-- into an unsigned one that 'sub' borrow can answer.  Uses r1 as a constant
-- holder; r1 is freely clobbered later by the comparing 'sub'.
emitSignedNorm :: CG ()
emitSignedNorm = do
  emitL "li r1, 0o4000"
  emitL "add r3, r3, r1"
  emitL "add r2, r2, r1"

-- After T is set such that T = 1 means "negative result":
-- ttoR2 False -> r2 = T          (used when T=1 means TRUE)
-- ttoR2 True  -> r2 = NOT T      (used when T=1 means FALSE)
ttoR2 :: Bool -> CG ()
ttoR2 invert = do
  if not invert
    then emitL "rol r2, r0"        -- r2 = T (clears T)
    else do
      lSkip <- freshLbl "ne"
      emitL "li r2, 1"              -- assume true
      emitL ("bf " <> lSkip)
      emitL "li r2, 0"              -- T was 1: result is false
      emit (lSkip <> ":")

-- Variable-amount shift: r3 = source, r2 = count.
-- isLeft: True = left shift; False = right shift.
-- isLogical: True = logical (zero-fill); False = arithmetic (sign-extend).
-- isLogical is ignored for left shifts (always zero-fill via clrt).
emitShift :: Bool -> Bool -> CG ()
emitShift isLeft isLogical = do
  lLoop <- freshLbl "shift_loop"
  lEnd  <- freshLbl "shift_end"
  emitL "and r2, r2, r2"            -- noop to mark start of shift
  -- Loop: while r2 > 0: shift r3 by 1; r2--.
  emit (lLoop <> ":")
  emitL "sub r0, r0, r2"            -- T = 1 iff r2 != 0
  emitL ("bf " <> lEnd)             -- exit when r2 == 0
  case (isLeft, isLogical) of
    (True, _)      -> do emitL "clrt"; emitL "rol r3, r3"
    (False, True)  -> do emitL "clrt"; emitL "ror r3, r3"
    (False, False) -> do              -- arithmetic: fill with sign bit
      emitL "and r1, r3, r7"         -- r1 = r3
      emitL "rol r1, r1"             -- T = bit 11 of r3 (sign bit)
      emitL "ror r3, r3"             -- r3 >>= 1, bit 11 filled with T
  emitL "subi r2, 1"
  emitL "sub r0, r0, r7"
  emitL ("bt " <> lLoop)
  emit (lEnd <> ":")
  emitL "and r2, r3, r7"

-- Multiply by repeated addition (uses r1 as accumulator).
-- Inputs: r3 = a, r2 = b. Output: r2 = a*b.
emitMul :: CG ()
emitMul = do
  lLoop <- freshLbl "mul_loop"
  lEnd  <- freshLbl "mul_end"
  emitL "and r1, r0, r0"            -- r1 = 0 (accumulator)
  emit (lLoop <> ":")
  emitL "sub r0, r0, r2"            -- T = 1 iff b != 0
  emitL ("bf " <> lEnd)
  emitL "add r1, r1, r3"
  emitL "subi r2, 1"
  emitL "sub r0, r0, r7"
  emitL ("bt " <> lLoop)
  emit (lEnd <> ":")
  emitL "and r2, r1, r7"

-- Unsigned division: r3=|n|, r2=|d| → r1=quotient, r4=remainder.
-- r2 and r3 are unchanged by this routine.
emitUDiv :: CG ()
emitUDiv = do
  lLoop <- freshLbl "udiv_loop"
  lEnd  <- freshLbl "udiv_end"
  emitL "and r4, r3, r7"            -- r4 = |n| (working remainder)
  emitL "and r1, r0, r0"            -- r1 = 0  (quotient)
  emit (lLoop <> ":")
  emitL "sub r0, r4, r2"            -- T=1 iff r4 < r2 (done)
  emitL ("bt " <> lEnd)
  emitL "sub r4, r4, r2"            -- r4 -= |d|
  emitL "addi r1, 1"
  emitL "sub r0, r0, r7"            -- T=1 unconditionally
  emitL ("bt " <> lLoop)
  emit (lEnd <> ":")

-- Fresh local label within a procedure (uses cgFuncName for uniqueness).
freshLbl :: Text -> CG Text
freshLbl base = do
  ls <- gets cgLines
  let n = length ls   -- monotonic counter; not perfectly unique but adequate
  fn <- gets cgFuncName
  pure $ "_L_" <> fn <> "_" <> base <> "_" <> tshow n
