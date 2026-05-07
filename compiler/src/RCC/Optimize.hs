module RCC.Optimize
  ( optimize
  ) where

import Data.Bits
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified RCC.TAC as TAC

optimize :: TAC.TACProg -> TAC.TACProg
optimize = foldBranches . foldConstants

type ConstMap = Map TAC.Temp Int

mask12 :: Int -> Int
mask12 x = x .&. 0xFFF

signed12 :: Int -> Int
signed12 x = if x >= 0o4000 then x - 0o10000 else x

foldConstants :: TAC.TACProg -> TAC.TACProg
foldConstants prog = prog { TAC.tacProcs = map foldProc (TAC.tacProcs prog) }

foldProc :: TAC.Proc -> TAC.Proc
foldProc p = p { TAC.procInstrs = go Map.empty (TAC.procInstrs p) }

go :: ConstMap -> [TAC.Instr] -> [TAC.Instr]
go _ [] = []
go _  (TAC.ILabel lbl : rest) = TAC.ILabel lbl : go Map.empty rest
go cm (TAC.IAssign t op : rest) =
    let op' = substOp cm op
        cm' = case op' of
                TAC.OConst n -> Map.insert t n cm
                _            -> Map.delete t cm
    in TAC.IAssign t op' : go cm' rest
go cm (TAC.IBinOp t op a b : rest) =
    let a' = substOp cm a
        b' = substOp cm b
    in case (a', b') of
        (TAC.OConst av, TAC.OConst bv) ->
            let v = foldBinOp op av bv
            in TAC.IAssign t (TAC.OConst v) : go (Map.insert t v cm) rest
        _ -> TAC.IBinOp t op a' b' : go (Map.delete t cm) rest
go cm (TAC.IUnOp t op a : rest) =
    let a' = substOp cm a
    in case a' of
        TAC.OConst av ->
            let v = foldUnaryOp op av
            in TAC.IAssign t (TAC.OConst v) : go (Map.insert t v cm) rest
        _ -> TAC.IUnOp t op a' : go (Map.delete t cm) rest
go cm (instr : rest) = substInstr cm instr : go (invalidate instr cm) rest

substOp :: ConstMap -> TAC.Operand -> TAC.Operand
substOp cm (TAC.OTemp t) | Just v <- Map.lookup t cm = TAC.OConst v
substOp _  op = op

substInstr :: ConstMap -> TAC.Instr -> TAC.Instr
substInstr cm (TAC.ILoad t op)        = TAC.ILoad t (substOp cm op)
substInstr cm (TAC.IStore op1 op2)    = TAC.IStore (substOp cm op1) (substOp cm op2)
substInstr cm (TAC.IIfNZ op lbl)      = TAC.IIfNZ (substOp cm op) lbl
substInstr cm (TAC.IIfZ op lbl)       = TAC.IIfZ (substOp cm op) lbl
substInstr cm (TAC.IReturn (Just op)) = TAC.IReturn (Just (substOp cm op))
substInstr cm (TAC.ICall mt f args)   = TAC.ICall mt f (map (substOp cm) args)
substInstr _  instr                   = instr

invalidate :: TAC.Instr -> ConstMap -> ConstMap
invalidate (TAC.IAssign  t _)       cm = Map.delete t cm
invalidate (TAC.IBinOp   t _ _ _)   cm = Map.delete t cm
invalidate (TAC.IUnOp    t _ _)     cm = Map.delete t cm
invalidate (TAC.ILoad    t _)       cm = Map.delete t cm
invalidate (TAC.ICall (Just t) _ _) cm = Map.delete t cm
invalidate _                        cm = cm

foldBinOp :: TAC.BinOp -> Int -> Int -> Int
foldBinOp op a b = mask12 result
  where
    result = case op of
      TAC.TAdd  -> a + b
      TAC.TSub  -> a - b
      TAC.TMul  -> a * b
      TAC.TDiv  -> if b == 0 then 0 else signed12 a `quot` signed12 b
      TAC.TMod  -> if b == 0 then 0 else signed12 a `rem`  signed12 b
      TAC.TBand -> a .&. b
      TAC.TBor  -> a .|. b
      TAC.TBxor -> xor a b
      TAC.TShl  -> (a `shiftL` (b `mod` 12)) .&. 0xFFF
      TAC.TShr  -> mask12 (signed12 a `shiftR` (b `mod` 12))
      TAC.TUShr -> a `shiftR` (b `mod` 12)
      TAC.TEq   -> if a == b then 1 else 0
      TAC.TNe   -> if a /= b then 1 else 0
      TAC.TLt   -> if signed12 a <  signed12 b then 1 else 0
      TAC.TLe   -> if signed12 a <= signed12 b then 1 else 0
      TAC.TGt   -> if signed12 a >  signed12 b then 1 else 0
      TAC.TGe   -> if signed12 a >= signed12 b then 1 else 0
      TAC.TULt  -> if a < b then 1 else 0
      TAC.TULe  -> if a <= b then 1 else 0
      TAC.TUGt  -> if a > b then 1 else 0
      TAC.TUGe  -> if a >= b then 1 else 0
      _         -> 0  -- TAnd/TOr: unreachable after lowering

foldUnaryOp :: TAC.UnOp -> Int -> Int
foldUnaryOp TAC.TNeg  x = mask12 (negate x)
foldUnaryOp TAC.TNot  x = if x == 0 then 1 else 0
foldUnaryOp TAC.TBNot x = mask12 (complement x)

-- ---------------------------------------------------------------------------
-- Constant branch folding

foldBranches :: TAC.TACProg -> TAC.TACProg
foldBranches prog = prog { TAC.tacProcs = map foldBranchesProc (TAC.tacProcs prog) }

foldBranchesProc :: TAC.Proc -> TAC.Proc
foldBranchesProc p = p { TAC.procInstrs = foldBranchInstrs (TAC.procInstrs p) }

foldBranchInstrs :: [TAC.Instr] -> [TAC.Instr]
foldBranchInstrs [] = []
foldBranchInstrs (i:rest) = case i of
  TAC.IIfZ  (TAC.OConst 0) lbl -> TAC.IGoto lbl   : foldBranchInstrs rest
  TAC.IIfZ  (TAC.OConst _) _   ->                    foldBranchInstrs rest  -- always false
  TAC.IIfNZ (TAC.OConst 0) _   ->                    foldBranchInstrs rest  -- never taken
  TAC.IIfNZ (TAC.OConst _) lbl -> TAC.IGoto lbl   : foldBranchInstrs rest
  _                             -> i               : foldBranchInstrs rest
