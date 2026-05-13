{-# LANGUAGE OverloadedStrings #-}
module RCC.Ir.SSA.CFG
  ( buildCFG
  , cfgFromRawBlockList
  , cfgToSsaFunc
  , RawBlock(..)
  , RawTerm(..)
  , nullRawBlock
  , Jump(..)
  , UTerm(..)
  , BlockId(..)
  , CFG(..)
  , Block(..)
  , Term(..)
  , tacOperandToValue
  , tacInstrsToSsaBody
  , resolveRawTerm
  ) where

import Data.List (foldl', nub)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe (mapMaybe)

import qualified RCC.Ir.SSA.IR as S
import qualified RCC.Ir.TAC as TAC

newtype BlockId = BlockId { unBlockId :: Int }
  deriving (Show, Eq, Ord)

-- | Resolved control-flow (used in 'Block' after label resolution).
data Term
  = TGoto BlockId
  | TIfZ S.Value BlockId BlockId
  | TIfNZ S.Value BlockId BlockId
  | TIfCmp TAC.BinOp S.Value S.Value BlockId BlockId
  | TIfNCmp TAC.BinOp S.Value S.Value BlockId BlockId
  | TReturn (Maybe S.Value)
  deriving (Show, Eq)

data Block = Block
  { bId     :: BlockId
  , bLabel  :: Maybe TAC.Label
  , bBody   :: [S.Instr]
  , bTerm   :: Term
  , bPreds  :: [BlockId]
  , bSuccs  :: [BlockId]
  } deriving (Show)

data CFG = CFG
  { cfgName   :: TAC.Label
  , cfgParams :: [TAC.Temp]
  , cfgEntry  :: BlockId
  , cfgBlocks :: Map BlockId Block
  , cfgLabelMap :: Map TAC.Label BlockId
  } deriving (Show)

-- | Forward / fallthrough jump before 'cfgLabelMap' is complete.
data Jump
  = JLab TAC.Label
  | JFall
  deriving (Show, Eq)

-- | Terminator while lowering (labels + fallthrough).
data UTerm
  = UTGoto Jump
  | UTIfZ S.Value Jump Jump
  | UTIfNZ S.Value Jump Jump
  | UTIfCmp TAC.BinOp S.Value S.Value Jump Jump
  | UTIfNCmp TAC.BinOp S.Value S.Value Jump Jump
  | UTReturn (Maybe S.Value)
  deriving (Show, Eq)

-- | Either an unresolved 'UTerm' or an already-resolved 'Term' (from 'buildCFG').
data RawTerm
  = URT UTerm
  | RRT Term
  deriving (Show, Eq)

data RawBlock = RawBlock
  { rbId    :: BlockId
  , rbLabel :: Maybe TAC.Label
  , rbBody  :: [S.Instr]
  , rbTerm  :: RawTerm
  } deriving (Show)

-- | Drop only degenerate placeholders (no label, no instrs, fallthrough stub).
nullRawBlock :: RawBlock -> Bool
nullRawBlock b =
  rbLabel b == Nothing && null (rbBody b) &&
    case rbTerm b of
      URT (UTGoto JFall) -> True
      _                  -> False

resolveJump :: Map TAC.Label BlockId -> Maybe BlockId -> Jump -> BlockId
resolveJump _ ft JFall = maybe (BlockId (-1)) id ft
resolveJump m _ (JLab l) = Map.findWithDefault (BlockId 0) l m

resolveRawTerm :: Map TAC.Label BlockId -> Maybe BlockId -> RawTerm -> Term
resolveRawTerm _ _ (RRT t) = t
resolveRawTerm m ft (URT ut) = case ut of
  UTGoto j          -> TGoto (resolveJump m ft j)
  UTIfZ v j1 j2     -> TIfZ v (resolveJump m ft j1) (resolveJump m ft j2)
  UTIfNZ v j1 j2    -> TIfNZ v (resolveJump m ft j1) (resolveJump m ft j2)
  UTIfCmp op a b j1 j2 ->
    TIfCmp op a b (resolveJump m ft j1) (resolveJump m ft j2)
  UTIfNCmp op a b j1 j2 ->
    TIfNCmp op a b (resolveJump m ft j1) (resolveJump m ft j2)
  UTReturn mv       -> TReturn mv

cfgFromRawBlockList :: TAC.Label -> [TAC.Temp] -> [RawBlock] -> Either String CFG
cfgFromRawBlockList name params rbs0 = do
  let rbs = filter (not . nullRawBlock) rbs0
      entryId = BlockId 0
      lblMap = Map.fromList [(l, rbId rb) | rb <- rbs, Just l <- [rbLabel rb]]
      ids = map rbId rbs
      fallMap = Map.fromList (zip ids (map Just (drop 1 ids) ++ [Nothing]))
      bs0 =
        [ rawToBlock lblMap (Map.findWithDefault Nothing (rbId rb) fallMap) rb
        | rb <- rbs
        ]
      bs1 = linkBlocks bs0
      m = Map.fromList [(bId b, b) | b <- bs1]
  pure $ CFG name params entryId m lblMap

rawToBlock :: Map TAC.Label BlockId -> Maybe BlockId -> RawBlock -> Block
rawToBlock lblMap fallthrough rb =
  let term = resolveRawTerm lblMap fallthrough (rbTerm rb)
      succs = succsOf term
   in Block
        { bId = rbId rb
        , bLabel = rbLabel rb
        , bBody = rbBody rb
        , bTerm = term
        , bPreds = []
        , bSuccs = succs
        }

succsOf :: Term -> [BlockId]
succsOf (TGoto b) = filter (/= BlockId (-1)) (nub [b])
succsOf (TIfZ _ t f) = filter (/= BlockId (-1)) (nub [t, f])
succsOf (TIfNZ _ t f) = filter (/= BlockId (-1)) (nub [t, f])
succsOf (TIfCmp _ _ _ t f) = filter (/= BlockId (-1)) (nub [t, f])
succsOf (TIfNCmp _ _ _ t f) = filter (/= BlockId (-1)) (nub [t, f])
succsOf (TReturn _) = []

linkBlocks :: [Block] -> [Block]
linkBlocks bs0 =
  let predMap = foldl' addPred Map.empty bs0
   in map (fillPreds predMap) bs0
  where
    addPred m b =
      foldl' (\m' s -> Map.insertWith (++) s [bId b] m') m (bSuccs b)
    fillPreds pm b =
      b { bPreds = Map.findWithDefault [] (bId b) pm }

-- | Lowered CFG to an 'S.Func' with no @phi@ nodes (skips Cytron SSA).
-- Terminators match the mapping used in "RCC.LowerToSSA" @cfgTermToSSA@.
cfgToSsaFunc :: CFG -> S.Func
cfgToSsaFunc g =
  S.Func
    (cfgName g)
    (cfgParams g)
    (toSid (cfgEntry g))
    (Map.mapKeys toSid (Map.map blockToS (cfgBlocks g)))
  where
    toSid :: BlockId -> S.BlockId
    toSid (BlockId n) = S.BlockId n
    blockToS :: Block -> S.Block
    blockToS b =
      S.Block
        (toSid (bId b))
        (bLabel b)
        (bBody b)
        (termToS (bTerm b))
        (map toSid (bPreds b))
        (map toSid (bSuccs b))
    termToS :: Term -> S.Term
    termToS (TGoto x) = S.TGoto (toSid x)
    termToS (TIfZ v tz fnz) = S.TBr v (toSid fnz) (toSid tz)
    termToS (TIfNZ v tnz tz) = S.TBr v (toSid tnz) (toSid tz)
    termToS (TIfCmp op a b t f) = S.TBrCmp False op a b (toSid t) (toSid f)
    termToS (TIfNCmp op a b t f) = S.TBrCmp True op a b (toSid t) (toSid f)
    termToS (TReturn mv) = S.TReturn mv

-- ---------------------------------------------------------------------------
-- Legacy: build CFG from flat TAC (tests / tacProcToSSA).

data TacRawBlock = TacRawBlock
  { trbId    :: BlockId
  , trbLabel :: Maybe TAC.Label
  , trbBody  :: [TAC.Instr]
  }

partitionTacBlocks :: [TAC.Instr] -> ([TacRawBlock], BlockId)
partitionTacBlocks instrs =
  let (bs, cur, _) = foldl' step ([], newBlock (BlockId 0) Nothing, 1) instrs
      bs' = bs ++ [finalize cur]
   in (filter (not . nullTacBlock) bs', BlockId 0)
  where
    newBlock bid ml = TacRawBlock bid ml []
    finalize = id
    nullTacBlock b = trbLabel b == Nothing && null (trbBody b)
    step (acc, cur, n) ins =
      case ins of
        TAC.ILabel l ->
          let acc' = acc ++ [finalize cur]
              cur' = newBlock (BlockId n) (Just l)
           in (acc', cur', n + 1)
        _ ->
          (acc, cur { trbBody = trbBody cur ++ [ins] }, n)

tacOperandToValue :: TAC.Operand -> S.Value
tacOperandToValue (TAC.OConst n)     = S.VConst n
tacOperandToValue (TAC.OAddr l)      = S.VAddr l
tacOperandToValue (TAC.OLocalAddr t) = S.VLocalAddr t
tacOperandToValue (TAC.OTemp t)      = S.VVar t

tacInstrToSsa :: TAC.Instr -> Maybe S.Instr
tacInstrToSsa (TAC.IComment t) = Just (S.IComment t)
tacInstrToSsa (TAC.ITargetAsm t) = Just (S.IEffect (S.OTargetAsm t))
tacInstrToSsa (TAC.IAllocLocal t) = Just (S.IComment ("alloclocal " <> t))
tacInstrToSsa (TAC.IStore a b) =
  Just (S.IStore (tacOperandToValue a) (tacOperandToValue b))
tacInstrToSsa (TAC.IAssign t o) =
  Just (S.IDef t (S.OCopy (tacOperandToValue o)))
tacInstrToSsa (TAC.IBinOp t op a b) =
  Just (S.IDef t (S.OBin op (tacOperandToValue a) (tacOperandToValue b)))
tacInstrToSsa (TAC.IUnOp t op a) =
  Just (S.IDef t (S.OUn op (tacOperandToValue a)))
tacInstrToSsa (TAC.ILoad t a) =
  Just (S.IDef t (S.OLoad (tacOperandToValue a)))
tacInstrToSsa (TAC.ICall mt f args) =
  let vs = map tacOperandToValue args
   in case mt of
        Nothing -> Just (S.IEffect (S.OCall f vs))
        Just t  -> Just (S.IDef t (S.OCall f vs))
tacInstrToSsa _ = Nothing

tacInstrsToSsaBody :: [TAC.Instr] -> [S.Instr]
tacInstrsToSsaBody = mapMaybe tacInstrToSsa

-- | Like old 'splitTerm' but operands become 'S.Value'.
splitTacTerm :: Map TAC.Label BlockId -> Maybe BlockId -> [TAC.Instr] -> ([TAC.Instr], Term)
splitTacTerm lblMap fallthrough xs =
  case reverse xs of
    [] ->
      case fallthrough of
        Just ft -> ([], TGoto ft)
        Nothing -> ([], TReturn Nothing)
    (lastI:restRev) ->
      let body = reverse restRev
       in case lastI of
            TAC.IGoto l ->
              (body, TGoto (lookupLbl l))
            TAC.IIfZ o l ->
              (body, TIfZ (tacOperandToValue o) (lookupLbl l) (fallOrRet fallthrough))
            TAC.IIfNZ o l ->
              (body, TIfNZ (tacOperandToValue o) (lookupLbl l) (fallOrRet fallthrough))
            TAC.IIfCmp op a b l ->
              ( body
              , TIfCmp op (tacOperandToValue a) (tacOperandToValue b)
                  (lookupLbl l) (fallOrRet fallthrough)
              )
            TAC.IIfNCmp op a b l ->
              ( body
              , TIfNCmp op (tacOperandToValue a) (tacOperandToValue b)
                  (lookupLbl l) (fallOrRet fallthrough)
              )
            TAC.IReturn mo ->
              (body, TReturn (fmap tacOperandToValue mo))
            _ ->
              case fallthrough of
                Just ft -> (xs, TGoto ft)
                Nothing -> (xs, TReturn Nothing)
  where
    lookupLbl l = Map.findWithDefault (BlockId 0) l lblMap
    fallOrRet (Just ft) = ft
    fallOrRet Nothing     = BlockId (-1)

tacRawToSsaRawFn :: Map TAC.Label BlockId -> Maybe BlockId -> TacRawBlock -> RawBlock
tacRawToSsaRawFn lblMap fallthrough rb =
  let (tacBody, termPart) = splitTacTerm lblMap fallthrough (trbBody rb)
      body = tacInstrsToSsaBody tacBody
   in RawBlock (trbId rb) (trbLabel rb) body (RRT termPart)

buildCFG :: TAC.Proc -> Either String CFG
buildCFG p =
  let (tacsF, _) = partitionTacBlocks (TAC.procInstrs p)
      lblMap = Map.fromList [(l, trbId b) | b <- tacsF, Just l <- [trbLabel b]]
      ids = map trbId tacsF
      fallMap = Map.fromList (zip ids (map Just (drop 1 ids) ++ [Nothing]))
      ssaRaws =
        [ tacRawToSsaRawFn lblMap (Map.findWithDefault Nothing (trbId tr) fallMap) tr
        | tr <- tacsF
        ]
   in cfgFromRawBlockList (TAC.procName p) (TAC.procParams p) ssaRaws
