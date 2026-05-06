module RCC.Codegen
  ( codegen
  , CodegenOpts(..)
  , defaultOpts
  ) where

import Control.Monad (when, forM_)
import Control.Monad.State
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import qualified Data.Set as Set
import Data.Set (Set)
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

-- ---------------------------------------------------------------------------
-- Per-procedure code generation state

data CGState = CGState
  { cgLines    :: [Text]            -- output (reversed)
  , cgSlots    :: Map TAC.Temp Int  -- temp -> slot offset from r6 (after prologue)
  , cgFrame    :: Int               -- number of param/temp slots
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
  ++ concatMap (genProc) procs
  ++ rodata
  ++ data_
  where
    prelude =
      [ "; rcc-generated assembly"
      , "    .org " <> octT (codeBase opts)
      , "_start:"
      , line ("li r6, " <> octT (stackTop opts))
      , line "li r1, main"
      , line "jalr r5, r1"
      , line "halt"
      , ""
      ]

    roGlobs = filter TAC.globalConst globals
    rwGlobs = filter (not . TAC.globalConst) globals

    rodata = if null roGlobs then [] else
      [""] ++ concatMap genGlobal roGlobs

    data_ = if null rwGlobs then [] else
      [ "", "    .org " <> octT (dataBase opts) ]
      ++ concatMap genGlobal rwGlobs

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

genProc :: TAC.Proc -> [Text]
genProc p =
  let temps   = collectTemps p
      slots   = Map.fromList (zip temps [0..])
      n       = length temps
      epi     = "_epi_" <> TAC.procName p
      initSt  = CGState [] slots n epi (TAC.procName p)
      numStack = max 0 (length (TAC.procParams p) - 3)
      action  = do
        emit ""
        emit (TAC.procName p <> ":")
        genPrologue p n
        mapM_ genInstr (TAC.procInstrs p)
        emit (epi <> ":")
        genEpilogue n numStack
  in reverse $ cgLines (execState action initSt)

-- Collect all unique Temp names used in a procedure (params + dest temps).
collectTemps :: TAC.Proc -> [TAC.Temp]
collectTemps p =
  let s0      = Set.fromList (TAC.procParams p)
      (_, ts) = foldl step (s0, TAC.procParams p) (TAC.procInstrs p)
  in ts
  where
    step (seen, acc) instr =
      let xs = instrTemps instr
          new = filter (`Set.notMember` seen) xs
      in (foldr Set.insert seen new, acc ++ new)

instrTemps :: TAC.Instr -> [TAC.Temp]
instrTemps (TAC.IAssign t _)        = [t]
instrTemps (TAC.IBinOp  t _ _ _)    = [t]
instrTemps (TAC.IUnOp   t _ _)      = [t]
instrTemps (TAC.ILoad   t _)        = [t]
instrTemps (TAC.ICall   (Just t) _ _) = [t]
instrTemps _ = []

-- Prologue: save r5, allocate slots, save params to slots.
-- We never use r4 inside the body, so r4 needs no save (callee-saved trivially).
genPrologue :: TAC.Proc -> Int -> CG ()
genPrologue p n = do
  -- Save r5
  emitL "addi r6, -1"
  emitL "swr r5, r6"
  -- Allocate slots for all temps
  when (n > 0) $ emitL ("addi r6, " <> tshow (negate n))
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
        emitL "and r1, r6, r7"
        emitL ("addi r1, " <> tshow stackOffset)
        emitL "lwr r2, r1"
        storeRegToTemp 2 paramName

genEpilogue :: Int -> Int -> CG ()
genEpilogue n numStack = do
  when (n > 0) $ emitL ("addi r6, " <> tshow n)
  emitL "lwr r5, r6"
  emitL "addi r6, 1"
  when (numStack > 0) $ emitL ("addi r6, " <> tshow numStack)
  emitL "jalr r0, r5"

-- ---------------------------------------------------------------------------
-- Loading and storing temps

-- Compute (r6 + slot) into r1.
addrOfSlot :: Int -> CG ()
addrOfSlot s = do
  emitL "and r1, r6, r7"
  when (s /= 0) $ emitL ("addi r1, " <> tshow s)

-- Load operand into the given register (2, 3, or 4).
loadOpInto :: Int -> TAC.Operand -> CG ()
loadOpInto reg (TAC.OConst n)  = emitL ("li r" <> tshow reg <> ", " <> tshow n)
loadOpInto reg (TAC.OAddr lbl) = emitL ("li r" <> tshow reg <> ", " <> lbl)
loadOpInto reg (TAC.OTemp t)   = do
  s <- slotOf t
  addrOfSlot s
  emitL ("lwr r" <> tshow reg <> ", r1")

-- Like loadOpInto but adds adj to the slot offset (compensates for r6 drift during arg pushes).
loadOpIntoAdj :: Int -> TAC.Operand -> Int -> CG ()
loadOpIntoAdj reg (TAC.OTemp t) adj = do
  s <- slotOf t
  emitL "and r1, r6, r7"
  let s' = s + adj
  when (s' /= 0) $ emitL ("addi r1, " <> tshow s')
  emitL ("lwr r" <> tshow reg <> ", r1")
loadOpIntoAdj reg op _ = loadOpInto reg op

storeRegToTemp :: Int -> TAC.Temp -> CG ()
storeRegToTemp reg t = do
  s <- slotOf t
  addrOfSlot s
  emitL ("swr r" <> tshow reg <> ", r1")

-- ---------------------------------------------------------------------------
-- Per-instruction codegen

genInstr :: TAC.Instr -> CG ()

genInstr (TAC.ILabel lbl) = emit (lbl <> ":")

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

genInstr (TAC.IIfZ op lbl) = do
  -- Branch to lbl when op == 0.  Long-form to avoid ±63 assembler limit.
  loadOpInto 2 op
  emitL "sub r0, r0, r2"          -- T = 1 iff op != 0
  lSkip <- freshLbl "ifz_skip"
  emitL ("bt " <> lSkip)          -- skip jump when op != 0
  emitL ("li r1, " <> lbl)
  emitL "jalr r0, r1"
  emit (lSkip <> ":")

genInstr (TAC.IIfNZ op lbl) = do
  -- Branch to lbl when op != 0.  Long-form.
  loadOpInto 2 op
  emitL "sub r0, r0, r2"          -- T = 1 iff op != 0
  lSkip <- freshLbl "ifnz_skip"
  emitL ("bf " <> lSkip)          -- skip jump when op == 0
  emitL ("li r1, " <> lbl)
  emitL "jalr r0, r1"
  emit (lSkip <> ":")

genInstr (TAC.ICall mt fname args) = do
  let regArgs   = take 3 args
      stackArgs = drop 3 args
      numStack  = length stackArgs
  -- Push stack args right-to-left; adjust slot offsets as r6 descends.
  forM_ (zip [0..] (reverse stackArgs)) $ \(k, op) -> do
    loadOpIntoAdj 2 op k
    emitL "addi r6, -1"
    emitL "swr r2, r6"
  -- Load register args; r6 is now numStack words below the frame base.
  forM_ (zip [2,3,4] regArgs) $ \(r, op) -> loadOpIntoAdj r op numStack
  -- Issue the call. Callee pops the stack args in its epilogue.
  emitL ("li r1, " <> fname)
  emitL "jalr r5, r1"
  -- Capture return value if requested.
  case mt of
    Just t  -> storeRegToTemp 2 t
    Nothing -> pure ()

genInstr (TAC.IReturn Nothing) = do
  epi <- gets cgEpiLabel
  emitL "sub r0, r0, r7"          -- T = 1
  emitL ("bt " <> epi)

genInstr (TAC.IReturn (Just op)) = do
  loadOpInto 2 op                 -- return value in r2
  epi <- gets cgEpiLabel
  emitL "sub r0, r0, r7"          -- T = 1
  emitL ("bt " <> epi)

-- ---------------------------------------------------------------------------
-- Binary operation codegen
--
-- Inputs: r3 = left, r2 = right.  Result placed in r2.

emitBinOp :: TAC.BinOp -> CG ()
emitBinOp TAC.TAdd = do
  emitL "clrt"
  emitL "addc r2, r3, r2"
emitBinOp TAC.TSub = do
  emitL "sub r2, r3, r2"
emitBinOp TAC.TBand = do
  emitL "and r2, r3, r2"
emitBinOp TAC.TBor = do
  -- r3 | r2 = (r3 + r2) - (r3 & r2)
  emitL "and r1, r3, r2"          -- r1 = r3 & r2
  emitL "clrt"
  emitL "addc r2, r3, r2"         -- r2 = r3 + r2
  emitL "sub r2, r2, r1"          -- r2 = (r3+r2) - (r3&r2)
emitBinOp TAC.TBxor = do
  -- r3 XOR r2 = (r3 | r2) - (r3 & r2)
  emitL "and r1, r3, r2"          -- r1 = r3 & r2
  emitL "clrt"
  emitL "addc r2, r3, r2"         -- r2 = r3 + r2
  emitL "sub r2, r2, r1"          -- r2 = (r3 | r2)
  emitL "sub r2, r2, r1"          -- r2 = XOR
emitBinOp TAC.TShl  = emitShift True  True   -- logical left
emitBinOp TAC.TShr  = emitShift False False  -- arithmetic right (sign-extending)
emitBinOp TAC.TUShr = emitShift False True   -- logical right (unsigned)
emitBinOp TAC.TMul = do
  -- Software multiply via __mul; not implemented in runtime, so use loop.
  emitMul
emitBinOp TAC.TDiv = do
  -- Not supported; emit zero.
  emitL "and r2, r0, r0"
emitBinOp TAC.TMod = do
  emitL "and r2, r0, r0"
emitBinOp TAC.TAnd = do
  -- Logical: should not appear (lowered to branches by TAC), but handle anyway.
  emitL "and r2, r3, r2"
emitBinOp TAC.TOr  = emitL "and r2, r3, r2"  -- placeholder

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
  emitL "li r1, 0o4000"            -- 2048
  emitL "clrt"
  emitL "addc r3, r3, r1"
  emitL "clrt"
  emitL "addc r2, r2, r1"

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
  emitL "addi r2, -1"
  emitL "sub r0, r0, r7"
  emitL ("bt " <> lLoop)
  emit (lEnd <> ":")
  emitL "and r2, r3, r7"            -- r2 = r3 (move)

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
  emitL "clrt"
  emitL "addc r1, r1, r3"           -- acc += a
  emitL "addi r2, -1"
  emitL "sub r0, r0, r7"
  emitL ("bt " <> lLoop)
  emit (lEnd <> ":")
  emitL "and r2, r1, r7"            -- r2 = acc

-- Fresh local label within a procedure (uses cgFuncName for uniqueness).
freshLbl :: Text -> CG Text
freshLbl base = do
  ls <- gets cgLines
  let n = length ls   -- monotonic counter; not perfectly unique but adequate
  fn <- gets cgFuncName
  pure $ "_L_" <> fn <> "_" <> base <> "_" <> tshow n
