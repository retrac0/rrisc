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

import RCC.Mach
  ( AsmLine (..)
  , Imm12 (..)
  , MachInsn (..)
  , Reg (..)
  , imm6
  , machLoadConst
  , reg
  , renderAsmProgram
  )
import RCC.RuntimeDeps (asmCalleeName, floatRuntimeIncludeLines, floatRuntimeIncludeLinesAll)

-- ---------------------------------------------------------------------------
-- Options

data CodegenOpts = CodegenOpts
  { codeBase :: Int
  , dataBase :: Int
  , stackTop :: Int
  -- | When true, do not append @%include@ float runtime files. Use when this
  -- object will be linked with another rcc object that already provides them
  -- (avoids duplicate symbols such as @__fstore_zero@).
  , omitFloatRuntime :: Bool
  -- | When true, @%include@ the full soft-float library even if this TU does not
  -- reference every helper (for multi-object links; pair with @omitFloatRuntime@
  -- on companion objects and a linker that resolves file-local labels across
  -- inputs).
  , embedFullFloatRuntime :: Bool
  } deriving (Show)

defaultOpts :: CodegenOpts
defaultOpts = CodegenOpts 0o1000 0o3000 0o3000 False False

-- ---------------------------------------------------------------------------
-- Helpers

tshow :: Show a => a -> Text
tshow = T.pack . show

octT :: Int -> Text
octT n = "0o" <> T.pack (showOct n "")

-- | Parse @%include "path"@ from a single-line preprocessed directive.
pathFromPercentInclude :: Text -> Text
pathFromPercentInclude t =
  let u = T.strip t
   in case T.stripPrefix "%include \"" u of
        Nothing -> error ("RCC.Codegen.pathFromPercentInclude: " <> T.unpack t)
        Just rest -> fst (T.breakOn "\"" rest)

-- ---------------------------------------------------------------------------
-- Per-procedure code generation state

data CGState = CGState
  { cgLines    :: [AsmLine]         -- output (reversed)
  , cgSlots    :: Map TAC.Temp Int  -- temp -> slot offset from r6 (after prologue)
  , cgEpiLabel :: TAC.Label
  , cgFuncName :: TAC.Label
  }

type CG = State CGState

emitAsm :: AsmLine -> CG ()
emitAsm x = modify $ \s -> s { cgLines = x : cgLines s }

emitInstr :: MachInsn -> CG ()
emitInstr = emitAsm . AsmInstr

emitInss :: [MachInsn] -> CG ()
emitInss = mapM_ emitInstr

emitLoadConst :: Int -> Int -> CG ()
emitLoadConst r n = emitInss (machLoadConst (reg r) n)

emitLiSym :: Int -> TAC.Label -> CG ()
emitLiSym r sym = emitInstr (ILiLabel (reg r) sym)

emitLiOct :: Int -> Int -> CG ()
emitLiOct r n = emitInstr (ILi (reg r) (Imm12Oct n))

slotOf :: TAC.Temp -> CG Int
slotOf t = do
  m <- gets cgSlots
  case Map.lookup t m of
    Just s  -> pure s
    Nothing -> error ("RCC.Codegen.slotOf: missing stack slot for temp " <> T.unpack t)

-- ---------------------------------------------------------------------------
-- Top-level codegen

codegen :: CodegenOpts -> TAC.TACProg -> Text
codegen opts prog@(TAC.TACProg globals procs) =
  renderAsmProgram $
    prelude
      ++ rwPackedData
      ++ textSectionDecl
      ++ concatMap genProc procs
      ++ floatRuntimeBlock
      ++ librccRuntimeBlock
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
      [ AsmSemiComment "rcc-generated assembly"
      , AsmPreprocDefine "RCC_CODE_BASE" (octT effectiveCodeBase)
      , AsmPreprocDefine "RCC_DATA_BASE" (octT (dataBase opts))
      , AsmPreprocDefine "RCC_STACK_TOP" (octT (stackTop opts))
      ]

    rwPackedData =
      if null rwGlobs || splitMemLayout
        then []
        else
          AsmBlank
            : AsmSection "data"
            : concatMap genGlobal rwGlobs

    textSectionDecl =
      [ AsmBlank
      , AsmSection "text"
      ]

    rwSplitData =
      if splitMemLayout && not (null rwGlobs)
        then
          AsmBlank
            : AsmSection "data"
            : concatMap genGlobal rwGlobs
        else []

    rodata = if null roGlobs then [] else AsmBlank : concatMap genGlobal roGlobs

    floatRuntimeBlock
      | omitFloatRuntime opts = []
      | embedFullFloatRuntime opts =
          case floatRuntimeIncludeLinesAll of
            [] -> []
            incs ->
              AsmBlank
                : AsmSemiComment "rcc: runtime library (full, for multi-object link)"
                : map (AsmPreprocInclude . pathFromPercentInclude) incs
      | otherwise =
          case floatRuntimeIncludeLines prog of
            [] -> []
            incs ->
              AsmBlank
                : AsmSemiComment "rcc: runtime library (auto-included)"
                : map (AsmPreprocInclude . pathFromPercentInclude) incs

    librccRuntimeBlock =
      if any (procUsesLibrcc . TAC.procInstrs) procs
        then
          [ AsmBlank
          , AsmSemiComment "rcc: lib/librcc.s (integer multiply/divide/modulo)"
          , AsmPreprocInclude "librcc.s"
          ]
        else []

genGlobal :: TAC.Global -> [AsmLine]
genGlobal g =
  AsmLabelDef (TAC.globalName g) : body
  where
    sz = TAC.globalSize g
    init_ = TAC.globalInit g
    body
      | null init_ = [AsmDirFill sz]
      | otherwise =
          AsmDirWord init_
            : if length init_ < sz
              then [AsmDirFill (sz - length init_)]
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

genProc :: TAC.Proc -> [AsmLine]
genProc p =
  let temps      = collectTemps p
      (slots, n) = buildSlotMap (TAC.procLocSzs p) temps
      epi     = "_epi_" <> TAC.procName p
      initSt  = CGState [] slots epi (TAC.procName p)
      numStack = max 0 (length (TAC.procParams p) - 3)
      isLeaf   =
        not (any isCallInstr (TAC.procInstrs p))
          && not (procUsesLibrcc (TAC.procInstrs p))
      usedTemps = collectUsedTemps (TAC.procInstrs p)
      action  = do
        emitAsm AsmBlank
        emitAsm (AsmGlobal (TAC.procName p))
        emitAsm (AsmLabelDef (TAC.procName p))
        genPrologue p n isLeaf usedTemps
        mapM_ genInstr (TAC.procInstrs p)
        emitAsm (AsmLabelDef epi)
        genEpilogue n numStack isLeaf
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

isCallInstr :: TAC.Instr -> Bool
isCallInstr (TAC.ICall _ _ _) = True
isCallInstr _                 = False

foldConstMulPure :: TAC.Operand -> TAC.Operand -> Bool
foldConstMulPure (TAC.OConst _) (TAC.OConst _) = True
foldConstMulPure _ _                           = False

signed12 :: Int -> Int
signed12 x =
  let v = x .&. 0xFFF
  in if v > 2047 then v - 4096 else v

foldConstDivMod :: TAC.BinOp -> TAC.Operand -> TAC.Operand -> Maybe (CG ())
foldConstDivMod TAC.TUDiv (TAC.OConst ka) (TAC.OConst kb) =
  let ua = ka .&. 0xFFF
      ub = kb .&. 0xFFF
  in Just $ emitLoadConst 2 (if ub == 0 then 0 else (ua `div` ub) .&. 0xFFF)
foldConstDivMod TAC.TUMod (TAC.OConst ka) (TAC.OConst kb) =
  let ua = ka .&. 0xFFF
      ub = kb .&. 0xFFF
  in Just $ emitLoadConst 2 (if ub == 0 then 0 else (ua `mod` ub) .&. 0xFFF)
foldConstDivMod TAC.TDiv (TAC.OConst ka) (TAC.OConst kb) =
  let sa = signed12 ka
      sb = signed12 kb
  in Just $ emitLoadConst 2 (if sb == 0 then 0 else (sa `quot` sb) .&. 0xFFF)
foldConstDivMod TAC.TMod (TAC.OConst ka) (TAC.OConst kb) =
  let sa = signed12 ka
      sb = signed12 kb
  in Just $ emitLoadConst 2 (if sb == 0 then 0 else (sa `rem` sb) .&. 0xFFF)
foldConstDivMod _ _ _ = Nothing

-- | Unsigned divide/modulo when divisor is a non-zero power of two (bit shifts / mask).
tryUnsignedDivModPow2 :: TAC.BinOp -> TAC.Operand -> TAC.Operand -> Maybe (CG ())
tryUnsignedDivModPow2 TAC.TUDiv a (TAC.OConst kb) =
  let k = kb .&. 0xFFF
  in if k /= 0 && isPow2 k
       then
         Just $ do
           loadOpInto 3 a
           emitLoadConst 2 (log2Pow2 k)
           emitShift False True
       else Nothing
tryUnsignedDivModPow2 TAC.TUMod a (TAC.OConst kb) =
  let k = kb .&. 0xFFF
  in if k /= 0 && isPow2 k
       then
         Just $ do
           loadOpInto 3 a
           emitLoadConst 2 (k - 1)
           emitInstr (IAnd R2 R3 R2)
       else Nothing
tryUnsignedDivModPow2 _ _ _ = Nothing

divModAvoidsRuntime :: TAC.BinOp -> TAC.Operand -> TAC.Operand -> Bool
divModAvoidsRuntime op a b =
  case foldConstDivMod op a b of
    Just _ -> True
    Nothing ->
      case tryUnsignedDivModPow2 op a b of
        Just _ -> True
        Nothing -> False

-- | True when @jalr@ into librcc (@__mul@, @__div@, …) may run (needs saved r5 like any call).
procUsesLibrcc :: [TAC.Instr] -> Bool
procUsesLibrcc = any $ \instr -> case instr of
  TAC.IBinOp _ TAC.TMul a b -> mulNeedsRuntimeLib a b
  TAC.IBinOp _ op a b
    | op `elem` [TAC.TDiv, TAC.TMod, TAC.TUDiv, TAC.TUMod] ->
        not (divModAvoidsRuntime op a b)
  _ -> False

mulNeedsRuntimeLib :: TAC.Operand -> TAC.Operand -> Bool
mulNeedsRuntimeLib a b
  | isZeroMulOp a || isZeroMulOp b = False
  | foldConstMulPure a b           = False
  | Just (k, _) <- mulConstFactor a b, mulByConstInline k = False
  | otherwise                      = True

collectUsedTemps :: [TAC.Instr] -> Set.Set TAC.Temp
collectUsedTemps instrs =
  Set.fromList $
    concatMap instrOperandTemps instrs

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
genPrologue :: TAC.Proc -> Int -> Bool -> Set.Set TAC.Temp -> CG ()
genPrologue p n isLeaf usedTemps = do
  let saveR5 = not isLeaf
  -- Save r5 for non-leaf functions.
  when saveR5 $ do
    emitInstr (ISubi R6 (imm6 1))
    emitInstr (ISwr R5 R6)
  -- Allocate slots for all temps (addi unsigned 0..63; subi for decrements)
  when (n > 0) $
    if n <= 63
      then emitInstr (ISubi R6 (imm6 n))
      else do
        emitLoadConst 1 n
        emitInstr (ISub R6 R6 R1)
  -- Save parameters into their slots: r2/r3/r4 for the first three, stack for the rest.
  -- Stack args were pushed right-to-left by the caller; arg 4 is closest to the frame
  -- (at offset n+1 from r6 when r5 is saved, otherwise offset n), arg 5 at +1, etc.
  forM_ (zip [0..] (TAC.procParams p)) $ \(i, paramName) -> do
    when (Set.member paramName usedTemps) $
      case (i :: Int) of
        0 -> storeRegToTemp 2 paramName
        1 -> storeRegToTemp 3 paramName
        2 -> storeRegToTemp 4 paramName
        _ -> do
          let stackBase   = n + (if saveR5 then 1 else 0)
              stackOffset = stackBase + (i - 3)
          addrOfSlot stackOffset
          emitInstr (ILwr R2 R1)
          storeRegToTemp 2 paramName

genEpilogue :: Int -> Int -> Bool -> CG ()
genEpilogue n numStack isLeaf = do
  when (n > 0) $
    if n <= 63
      then emitInstr (IAddi R6 (imm6 n))
      else do
        emitLoadConst 1 n
        emitInstr (IAdd R6 R6 R1)
  when (not isLeaf) $ do
    emitInstr (ILwr R5 R6)
    emitInstr (IAddi R6 (imm6 1))
  when (numStack > 0) $ emitInstr (IAddi R6 (imm6 numStack))
  emitInstr (IJalr R0 R5)

-- ---------------------------------------------------------------------------
-- Loading and storing temps

-- Compute (r6 + slot) into r1.
addrOfSlot :: Int -> CG ()
addrOfSlot s
  | s == 0    = emitInstr (IAnd R1 R6 R7)
  | s <= 63   = do emitInstr (IAnd R1 R6 R7)
                   emitInstr (IAddi R1 (imm6 s))
  | otherwise = do emitLoadConst 1 s
                   emitInstr (IAdd R1 R1 R6)

-- Emit the most compact single instruction that loads constant n into reg.
-- val = n masked to 12 bits.
--   val == 0:              and rx, r0, r0  (1 word)
--   val == 0xFFF (i.e. -1): and rx, r7, r7  (1 word)
--   lower 6 bits zero:     lui rx, val>>6  (1 word, rx not r0/r7)
--   otherwise:             li rx, n        (2 words)
-- Load operand into the given register (2, 3, or 4).
loadOpInto :: Int -> TAC.Operand -> CG ()
loadOpInto r (TAC.OConst n)  = emitLoadConst r n
loadOpInto r (TAC.OAddr lbl) = emitLiSym r lbl
loadOpInto r (TAC.OTemp t)   = do
  s <- slotOf t
  addrOfSlot s
  emitInstr (ILwr (reg r) R1)
loadOpInto r (TAC.OLocalAddr t) = do
  s <- slotOf t
  addrOfSlot s
  when (r /= 1) $ emitInstr (IAnd (reg r) R1 R7)

-- Like loadOpInto but adds adj to the slot offset (compensates for r6 drift during arg pushes).
loadOpIntoAdj :: Int -> TAC.Operand -> Int -> CG ()
loadOpIntoAdj r (TAC.OTemp t) adj = do
  s <- slotOf t
  let s' = s + adj
  addrOfSlot s'
  emitInstr (ILwr (reg r) R1)
loadOpIntoAdj r (TAC.OLocalAddr t) adj = do
  s <- slotOf t
  let s' = s + adj
  addrOfSlot s'
  when (r /= 1) $ emitInstr (IAnd (reg r) R1 R7)
loadOpIntoAdj r op _ = loadOpInto r op

storeRegToTemp :: Int -> TAC.Temp -> CG ()
storeRegToTemp r t = do
  s <- slotOf t
  addrOfSlot s
  emitInstr (ISwr (reg r) R1)

-- ---------------------------------------------------------------------------
-- Per-instruction codegen

genInstr :: TAC.Instr -> CG ()
genInstr (TAC.ILabel      lbl) = emitAsm (AsmLabelDef lbl)
genInstr (TAC.IComment    txt) = emitAsm (AsmComment txt)
genInstr (TAC.IAllocLocal _  ) = pure ()  -- slot reserved by buildSlotMap; no code needed
genInstr (TAC.IAsmInline  txt) =
  when (not (T.null txt)) (emitAsm (AsmUserAsmInline txt))

genInstr (TAC.IAssign t op) = do
  loadOpInto 2 op
  storeRegToTemp 2 t

genInstr (TAC.IBinOp t op a b)
  | op == TAC.TMul = genMulOp t a b
genInstr (TAC.IBinOp t op a b)
  | op `elem` [TAC.TDiv, TAC.TMod, TAC.TUDiv, TAC.TUMod] = genDivModOp t op a b
genInstr (TAC.IBinOp t op a b) = do
  loadOpInto 3 a       -- left in r3
  loadOpInto 2 b       -- right in r2
  emitBinOp op
  storeRegToTemp 2 t

genInstr (TAC.IUnOp t op a) = do
  loadOpInto 2 a
  case op of
    TAC.TNeg  -> emitInstr (ISub R2 R0 R2) -- r2 = 0 - r2
    TAC.TNot  -> do
      emitInstr (ISub R0 R0 R2) -- T = 1 iff r2 != 0
      lTrue <- freshLbl "not_zero"
      lEnd  <- freshLbl "not_end"
      emitInstr (IBt lTrue)
      emitInstr (ILi R2 (Imm12Dec 1))
      emitInstr (ISub R0 R0 R7)
      emitInstr (IBt lEnd)
      emitAsm (AsmLabelDef lTrue)
      emitInstr (ILi R2 (Imm12Dec 0))
      emitAsm (AsmLabelDef lEnd)
    TAC.TBNot -> emitInstr (ISub R2 R7 R2) -- r2 = -1 - r2 = ~r2
  storeRegToTemp 2 t

genInstr (TAC.ILoad t addr) = do
  loadOpInto 1 addr               -- address in r1
  emitInstr (ILwr R2 R1)          -- r2 = mem[r1]
  storeRegToTemp 2 t

genInstr (TAC.IStore addr val) = do
  loadOpInto 2 val                -- value in r2
  loadOpInto 1 addr               -- address in r1 (doesn't clobber r2)
  emitInstr (ISwr R2 R1)         -- mem[r1] = r2

genInstr (TAC.IGoto lbl) = do
  emitInstr IClrt
  emitInstr (IBf lbl)

genInstr (TAC.IIfCmp op a b lbl) = do
  emitCmpToT op a b >>= \inv ->
    if inv then jumpOnNotT lbl else jumpOnT lbl

genInstr (TAC.IIfNCmp op a b lbl) = do
  emitCmpToT op a b >>= \inv ->
    if inv then jumpOnT lbl else jumpOnNotT lbl

genInstr (TAC.IIfZ op lbl) = do
  -- T=1 iff op!=0; branch when op==0. Assembler relaxes bf if out of ±63 range.
  loadOpInto 2 op
  emitInstr (ISub R0 R0 R2)
  emitInstr (IBf lbl)

genInstr (TAC.IIfNZ op lbl) = do
  loadOpInto 2 op
  emitInstr (ISub R0 R0 R2)
  emitInstr (IBt lbl)

genInstr (TAC.ICall mt fname args) = do
  let regArgs   = take 3 args
      stackArgs = drop 3 args
      numStack  = length stackArgs
  -- Push stack args right-to-left; adjust slot offsets as r6 descends.
  forM_ (zip [0..] (reverse stackArgs)) $ \(k, op) -> do
    loadOpIntoAdj 2 op k
    emitInstr (ISubi R6 (imm6 1))
    emitInstr (ISwr R2 R6)
  -- Load register args; r6 is now numStack words below the frame base.
  forM_ (zip [2,3,4] regArgs) $ \(r, op) -> loadOpIntoAdj r op numStack
  -- Issue the call. Callee pops the stack args in its epilogue.
  emitLiSym 1 (asmCalleeName fname)
  emitInstr (IJalr R5 R1)
  -- Capture return value if requested.
  case mt of
    Just t  -> storeRegToTemp 2 t
    Nothing -> pure ()

genInstr (TAC.IReturn Nothing) = do
  epi <- gets cgEpiLabel
  emitInstr IClrt
  emitInstr (IBf epi)

genInstr (TAC.IReturn (Just op)) = do
  loadOpInto 2 op                 -- return value in r2
  epi <- gets cgEpiLabel
  emitInstr IClrt
  emitInstr (IBf epi)

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
      emitInstr (ISub R1 R3 R2)
      emitInstr (ISub R0 R0 R1) -- T=1 iff a!=b
      pure False
    TAC.TEq -> do
      emitInstr (ISub R1 R3 R2)
      emitInstr (ISub R0 R0 R1) -- T=1 iff a!=b (inverted)
      pure True
    TAC.TULt -> do
      emitInstr (ISub R1 R3 R2) -- T=1 iff a<b unsigned
      pure False
    TAC.TUGt -> do
      emitInstr (ISub R1 R2 R3) -- T=1 iff b<a
      pure False
    TAC.TULe -> do
      emitInstr (ISub R1 R2 R3) -- T=1 iff a>b (inverted)
      pure True
    TAC.TUGe -> do
      emitInstr (ISub R1 R3 R2) -- T=1 iff a<b (inverted)
      pure True
    TAC.TLt -> do
      emitSignedNorm
      emitInstr (ISub R1 R3 R2) -- T=1 iff a<b signed
      pure False
    TAC.TGt -> do
      emitSignedNorm
      emitInstr (ISub R1 R2 R3) -- T=1 iff a>b signed
      pure False
    TAC.TLe -> do
      emitSignedNorm
      emitInstr (ISub R1 R2 R3) -- T=1 iff a>b (inverted)
      pure True
    TAC.TGe -> do
      emitSignedNorm
      emitInstr (ISub R1 R3 R2) -- T=1 iff a<b (inverted)
      pure True
    _ -> do
      -- Not expected for IIfCmp/IIfNCmp; fall back to boolean materialization path.
      case op of
        TAC.TDiv  -> emitDivModLibrary TAC.TDiv
        TAC.TMod  -> emitDivModLibrary TAC.TMod
        TAC.TUDiv -> emitDivModLibrary TAC.TUDiv
        TAC.TUMod -> emitDivModLibrary TAC.TUMod
        _         -> emitBinOp op
      emitInstr (ISub R0 R0 R2)
      pure False

jumpOnT :: TAC.Label -> CG ()
jumpOnT lbl = emitInstr (IBt lbl)

jumpOnNotT :: TAC.Label -> CG ()
jumpOnNotT lbl = emitInstr (IBf lbl)

-- ---------------------------------------------------------------------------
-- Binary operation codegen
--
-- Inputs: r3 = left, r2 = right.  Result placed in r2.

emitBinOp :: TAC.BinOp -> CG ()
emitBinOp TAC.TAdd = do
  emitInstr (IAdd R2 R3 R2)
emitBinOp TAC.TSub = do
  emitInstr (ISub R2 R3 R2)
emitBinOp TAC.TBand = do
  emitInstr (IAnd R2 R3 R2)
emitBinOp TAC.TBor = do
  -- r3 | r2 = (r3 + r2) - (r3 & r2)
  emitInstr (IAnd R1 R3 R2)
  emitInstr (IAdd R2 R3 R2)
  emitInstr (ISub R2 R2 R1)
emitBinOp TAC.TBxor = do
  -- r3 XOR r2 = (r3 | r2) - (r3 & r2) - (r3 & r2)
  emitInstr (IAnd R1 R3 R2)
  emitInstr (IAdd R2 R3 R2)
  emitInstr (ISub R2 R2 R1)
  emitInstr (ISub R2 R2 R1)
emitBinOp TAC.TShl  = emitShift True  True   -- logical left
emitBinOp TAC.TShr  = emitShift False False  -- arithmetic right (sign-extending)
emitBinOp TAC.TUShr = emitShift False True   -- logical right (unsigned)
emitBinOp TAC.TMul = emitMulLibraryAfterLoads -- r3=a, r2=b already loaded (rare direct path)
emitBinOp TAC.TDiv =
  error "RCC.Codegen.emitBinOp: TDiv lowered via genDivModOp only"
emitBinOp TAC.TMod =
  error "RCC.Codegen.emitBinOp: TMod lowered via genDivModOp only"
emitBinOp TAC.TUDiv =
  error "RCC.Codegen.emitBinOp: TUDiv lowered via genDivModOp only"
emitBinOp TAC.TUMod =
  error "RCC.Codegen.emitBinOp: TUMod lowered via genDivModOp only"
emitBinOp TAC.TAnd = do
  -- Logical: should not appear (lowered to branches by TAC), but handle anyway.
  emitInstr (IAnd R2 R3 R2)
emitBinOp TAC.TOr = do
  emitInstr (IAnd R1 R3 R2)
  emitInstr (IAdd R2 R3 R2)
  emitInstr (ISub R2 R2 R1)

-- Comparisons: result in r2 as 0 or 1.
emitBinOp TAC.TEq = do
  emitInstr (ISub R1 R3 R2) -- r1 = a - b
  emitInstr (ISub R0 R0 R1) -- T = 1 iff (a - b) != 0
  ttoR2 True -- r2 = NOT T (1 if equal)
emitBinOp TAC.TNe = do
  emitInstr (ISub R1 R3 R2)
  emitInstr (ISub R0 R0 R1) -- T = 1 iff a != b
  ttoR2 False -- r2 = T
emitBinOp TAC.TLt = do
  emitSignedNorm
  emitInstr (ISub R1 R3 R2) -- T = 1 iff (a' < b') = (a < b signed)
  ttoR2 False
emitBinOp TAC.TGt = do
  emitSignedNorm
  emitInstr (ISub R1 R2 R3) -- T = 1 iff b' < a' = a > b
  ttoR2 False
emitBinOp TAC.TLe = do
  emitSignedNorm
  emitInstr (ISub R1 R2 R3) -- T = 1 iff a > b
  ttoR2 True -- r2 = NOT T = a <= b
emitBinOp TAC.TGe = do
  emitSignedNorm
  emitInstr (ISub R1 R3 R2) -- T = 1 iff a < b
  ttoR2 True -- r2 = NOT T = a >= b

-- Unsigned comparisons: borrow flag of 'sub' gives the answer directly.
emitBinOp TAC.TULt = do
  emitInstr (ISub R1 R3 R2) -- T = 1 iff a < b unsigned
  ttoR2 False
emitBinOp TAC.TUGt = do
  emitInstr (ISub R1 R2 R3) -- T = 1 iff b < a, i.e., a > b
  ttoR2 False
emitBinOp TAC.TULe = do
  emitInstr (ISub R1 R2 R3) -- T = 1 iff b < a (a > b)
  ttoR2 True -- NOT T = a <= b
emitBinOp TAC.TUGe = do
  emitInstr (ISub R1 R3 R2) -- T = 1 iff a < b
  ttoR2 True -- NOT T = a >= b

-- Add 2048 (sign-bit flip) to both r3 and r2 to convert signed comparison
-- into an unsigned one that 'sub' borrow can answer.  Uses r1 as a constant
-- holder; r1 is freely clobbered later by the comparing 'sub'.
emitSignedNorm :: CG ()
emitSignedNorm = do
  emitLiOct 1 0o4000
  emitInstr (IAdd R3 R3 R1)
  emitInstr (IAdd R2 R2 R1)

-- After T is set such that T = 1 means "negative result":
-- ttoR2 False -> r2 = T          (used when T=1 means TRUE)
-- ttoR2 True  -> r2 = NOT T      (used when T=1 means FALSE)
ttoR2 :: Bool -> CG ()
ttoR2 invert = do
  if not invert
    then emitInstr (IRol R2 R0) -- r2 = T (clears T)
    else do
      lSkip <- freshLbl "ne"
      emitInstr (ILi R2 (Imm12Dec 1)) -- assume true
      emitInstr (IBf lSkip)
      emitInstr (ILi R2 (Imm12Dec 0)) -- T was 1: result is false
      emitAsm (AsmLabelDef lSkip)

-- Variable-amount shift: r3 = source, r2 = count.
-- isLeft: True = left shift; False = right shift.
-- isLogical: True = logical (zero-fill); False = arithmetic (sign-extend).
-- isLogical is ignored for left shifts (always zero-fill via clrt).
emitShift :: Bool -> Bool -> CG ()
emitShift isLeft isLogical = do
  lLoop <- freshLbl "shift_loop"
  lEnd  <- freshLbl "shift_end"
  emitInstr (IAnd R2 R2 R2) -- noop to mark start of shift
  -- Loop: while r2 > 0: shift r3 by 1; r2--.
  emitAsm (AsmLabelDef lLoop)
  emitInstr (ISub R0 R0 R2) -- T = 1 iff r2 != 0
  emitInstr (IBf lEnd) -- exit when r2 == 0
  case (isLeft, isLogical) of
    (True, _) -> do emitInstr IClrt; emitInstr (IRol R3 R3)
    (False, True) -> do emitInstr IClrt; emitInstr (IRor R3 R3)
    (False, False) -> do -- arithmetic: fill with sign bit
      emitInstr (IAnd R1 R3 R7) -- r1 = r3
      emitInstr (IRol R1 R1) -- T = bit 11 of r3 (sign bit)
      emitInstr (IRor R3 R3) -- r3 >>= 1, bit 11 filled with T
  emitInstr (ISubi R2 (imm6 1))
  emitInstr (ISub R0 R0 R7)
  emitInstr (IBt lLoop)
  emitAsm (AsmLabelDef lEnd)
  emitInstr (IAnd R2 R3 R7)

-- ---------------------------------------------------------------------------
-- Integer multiply: strength-reduce small / power-of-two constants; otherwise
-- call runtime __mul (lib/librcc.s).

genMulOp :: TAC.Temp -> TAC.Operand -> TAC.Operand -> CG ()
genMulOp t a b
  | isZeroMulOp a || isZeroMulOp b = do emitLoadConst 2 0; storeRegToTemp 2 t
genMulOp t a b =
  case foldConstMul a b of
    Just cg -> do cg; storeRegToTemp 2 t
    Nothing ->
      case mulConstFactor a b of
        Just (k, varOp) | mulByConstInline k ->
          do emitMulByConst k varOp; storeRegToTemp 2 t
        _ -> do
          loadOpInto 3 a
          loadOpInto 2 b
          emitMulLibraryAfterLoads
          storeRegToTemp 2 t

isZeroMulOp :: TAC.Operand -> Bool
isZeroMulOp (TAC.OConst k) = (k .&. 0xFFF) == 0
isZeroMulOp _              = False

foldConstMul :: TAC.Operand -> TAC.Operand -> Maybe (CG ())
foldConstMul (TAC.OConst ka) (TAC.OConst kb) =
  Just $ emitLoadConst 2 ((ka * kb) .&. 0xFFF)
foldConstMul _ _ = Nothing


mulConstFactor :: TAC.Operand -> TAC.Operand -> Maybe (Int, TAC.Operand)
mulConstFactor (TAC.OConst k) rhs | k /= 0 = Just (k .&. 0xFFF, rhs)
mulConstFactor lhs (TAC.OConst k) | k /= 0 = Just (k .&. 0xFFF, lhs)
mulConstFactor _ _ = Nothing

mulByConstInline :: Int -> Bool
mulByConstInline k =
  k == 1 || isPow2 k || k == 3 || k == 5 || k == 6

isPow2 :: Int -> Bool
isPow2 k = k > 0 && (k .&. (k - 1)) == 0

log2Pow2 :: Int -> Int
log2Pow2 k = go 0 k
  where
    go n 1 = n
    go n x = go (n + 1) (x `shiftR` 1)

emitMulByConst :: Int -> TAC.Operand -> CG ()
emitMulByConst 1 v = loadOpInto 2 v
emitMulByConst k v | isPow2 k = do
  loadOpInto 3 v
  emitLoadConst 2 (log2Pow2 k)
  emitShift True True
emitMulByConst 3 v = do
  loadOpInto 3 v
  emitInstr (IAnd R4 R3 R7)
  emitLoadConst 2 1
  emitShift True True
  emitInstr (IAdd R2 R4 R2)
emitMulByConst 5 v = do
  loadOpInto 3 v
  emitInstr (IAnd R4 R3 R7)
  emitLoadConst 2 2
  emitShift True True
  emitInstr (IAdd R2 R4 R2)
emitMulByConst 6 v = do
  loadOpInto 3 v
  emitInstr (IAnd R4 R3 R7)
  emitLoadConst 2 2
  emitShift True True
  emitInstr (IAnd R1 R2 R7)
  loadOpInto 3 v
  emitLoadConst 2 1
  emitShift True True
  emitInstr (IAdd R2 R1 R2)
emitMulByConst k v = do
  loadOpInto 3 v
  emitLoadConst 2 k
  emitMulLibraryAfterLoads

emitMulLibraryAfterLoads :: CG ()
emitMulLibraryAfterLoads = emitLibrcc "__mul"

-- | Integer divide/modulo: const-fold, unsigned-by-power-of-two, else librcc (@jalr@).
genDivModOp :: TAC.Temp -> TAC.BinOp -> TAC.Operand -> TAC.Operand -> CG ()
genDivModOp t op a b =
  case foldConstDivMod op a b of
    Just cg -> do cg; storeRegToTemp 2 t
    Nothing ->
      case tryUnsignedDivModPow2 op a b of
        Just cg -> do cg; storeRegToTemp 2 t
        Nothing -> do
          loadOpInto 3 a
          loadOpInto 2 b
          emitDivModLibrary op
          storeRegToTemp 2 t

emitDivModLibrary :: TAC.BinOp -> CG ()
emitDivModLibrary op = case op of
  TAC.TDiv  -> emitLibrcc "__div"
  TAC.TMod  -> emitLibrcc "__mod"
  TAC.TUDiv -> emitLibrcc "__udiv"
  TAC.TUMod -> emitLibrcc "__umod"
  _         -> error "RCC.Codegen.emitDivModLibrary: expected div/mod opcode"

emitLibrcc :: Text -> CG ()
emitLibrcc sym = do
  emitLiSym 1 sym
  emitInstr (IJalr R5 R1)

-- Fresh local label within a procedure (uses cgFuncName for uniqueness).
freshLbl :: Text -> CG Text
freshLbl base = do
  ls <- gets cgLines
  let n = length ls
  fn <- gets cgFuncName
  pure $ "_L_" <> fn <> "_" <> base <> "_" <> tshow n
