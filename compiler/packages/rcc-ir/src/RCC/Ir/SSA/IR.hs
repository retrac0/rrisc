{-# LANGUAGE OverloadedStrings #-}
module RCC.Ir.SSA.IR
  ( BlockId(..)
  , Value(..)
  , Op(..)
  , Effect(..)
  , effectOf
  , Instr(..)
  , Term(..)
  , Block(..)
  , Func(..)
  , verifyFunc
  ) where

import Data.List (nub)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)

import qualified RCC.Ir.TAC as TAC

newtype BlockId = BlockId { unBlockId :: Int }
  deriving (Show, Eq, Ord)

-- | SSA value reference.
data Value
  = VVar Text
  | VConst Int
  | VAddr TAC.Label
  | VLocalAddr TAC.Temp
  deriving (Show, Eq, Ord)

data Op
  = OBin TAC.BinOp Value Value
  | OUn  TAC.UnOp Value
  | OCopy Value
  | OLoad Value          -- load from address value
  | OCall TAC.Label [Value]
  | -- | Opaque assembly text; only backends that understand this extension may interpret it.
    OTargetAsm Text
  deriving (Show, Eq)

data Effect = Pure | MayLoad | MayStore | CallLike | TargetAsmBarrier
  deriving (Show, Eq, Ord)

effectOf :: Op -> Effect
effectOf (OBin _ _ _) = Pure
effectOf (OUn _ _)    = Pure
effectOf (OCopy _)    = Pure
effectOf (OLoad _)    = MayLoad
effectOf (OCall _ _)  = CallLike
effectOf (OTargetAsm _) = TargetAsmBarrier

-- | SSA instruction: optional definition.
data Instr
  = IPhi Text [(BlockId, Value)]        -- x = phi(pred->val, ...)
  | IDef Text Op                        -- x = op ...
  | IEffect Op                          -- effectful op without a def
  | IStore Value Value                  -- *addr = val
  | IComment Text
  deriving (Show, Eq)

data Term
  = TGoto BlockId
  | TBr Value BlockId BlockId           -- if value != 0 then t else f
  | TBrCmp Bool TAC.BinOp Value Value BlockId BlockId
  -- ^ For compares: Bool indicates invert (True => branch when NOT (a op b)).
  | TReturn (Maybe Value)
  deriving (Show, Eq)

data Block = Block
  { bId    :: BlockId
  , bLabel :: Maybe TAC.Label
  , bInstrs :: [Instr]
  , bTerm  :: Term
  , bPreds :: [BlockId]
  , bSuccs :: [BlockId]
  } deriving (Show, Eq)

data Func = Func
  { fName   :: TAC.Label
  , fParams :: [TAC.Temp]
  , fEntry  :: BlockId
  , fBlocks :: Map BlockId Block
  } deriving (Show, Eq)

verifyFunc :: Func -> Either Text ()
verifyFunc f = do
  let bs = Map.elems (fBlocks f)
  if Map.member (fEntry f) (fBlocks f) then Right () else Left "entry block missing"
  mapM_ verifyBlock bs
  pure ()
  where
    verifyBlock b = do
      let okPred = all (`Map.member` fBlocks f) (bPreds b)
          okSucc = all (`Map.member` fBlocks f) (bSuccs b)
      if okPred then Right () else Left "block has missing pred"
      if okSucc then Right () else Left "block has missing succ"
      -- phi nodes must come first
      let (phis, rest) = span isPhi (bInstrs b)
      if any isPhi rest then Left "phi not at block start" else Right ()
      -- phi edges must reference only preds
      let ps = nub (bPreds b)
      mapM_ (phiPredsOk ps) phis

    isPhi (IPhi _ _) = True
    isPhi _          = False

    phiPredsOk ps (IPhi _ edges) =
      if all (\(p,_) -> p `elem` ps) edges then Right () else Left "phi edge from non-pred"
    phiPredsOk _ _ = Right ()

