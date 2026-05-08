{-# LANGUAGE OverloadedStrings #-}
module RCC.SSA.ToTAC
  ( fromSSA
  ) where

import Data.List (foldl')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T

import qualified RCC.SSA.IR as S
import qualified RCC.TAC as TAC

-- | Lower SSA back to TAC by eliminating phi nodes via edge-splitting.
fromSSA :: Map TAC.Temp Int -> S.Func -> TAC.Proc
fromSSA locSzs f =
  let blocks1 = splitPhiEdges (S.fBlocks f)
      (blocks2, labelMap) = ensureLabels (S.fName f) blocks1
      instrs = linearize blocks2 labelMap
   in TAC.Proc (S.fName f) (S.fParams f) instrs locSzs

ensureLabels :: Text -> Map S.BlockId S.Block -> (Map S.BlockId S.Block, Map S.BlockId TAC.Label)
ensureLabels fn blocks =
  let labels =
        Map.fromList
          [ (bid, "_B_" <> fn <> "_" <> T.pack (show (S.unBlockId bid)))
          | (bid, _) <- Map.toList blocks
          ]
      blocks' = Map.mapWithKey (\bid b -> b { S.bLabel = Just (labels Map.! bid) }) blocks
   in (blocks', labels)

collectPhis :: S.Block -> [(Text, [(S.BlockId, S.Value)])]
collectPhis b =
  [ (nm, edges)
  | S.IPhi nm edges <- S.bInstrs b
  ]

-- For each edge pred->succ that feeds phis, split it by inserting a new block with copies.
splitPhiEdges :: Map S.BlockId S.Block -> Map S.BlockId S.Block
splitPhiEdges blocks0 =
  let maxId = maximum (0 : [S.unBlockId bid | bid <- Map.keys blocks0])
      (blocks1, _) =
        foldl'
          (\(bs, next) (succId, succB) ->
             let phis = collectPhis succB
              in if null phis
                   then (bs, next)
                   else
                     foldl' (splitForSucc succId phis) (bs, next) (S.bPreds succB))
          (blocks0, maxId + 1)
          (Map.toList blocks0)
   in blocks1
  where
    splitForSucc succId phis (bs, next) predId =
      let assigns =
            [ (dst, val)
            | (dst, edges) <- phis
            , Just val <- [lookup predId edges]
            ]
       in if null assigns
            then (bs, next)
            else
              let newId = S.BlockId next
                  copyInstrs =
                    [ S.IDef dst (S.OCopy val)
                    | (dst, val) <- assigns
                    ]
                  newB = S.Block
                    { S.bId = newId
                    , S.bLabel = Nothing
                    , S.bInstrs = copyInstrs
                    , S.bTerm = S.TGoto succId
                    , S.bPreds = [predId]
                    , S.bSuccs = [succId]
                    }
                  bs1 = Map.insert newId newB bs
                  bs2 = Map.adjust (rewriteSucc succId newId) predId bs1
                  bs3 = Map.adjust (\b -> b { S.bPreds = replacePred predId newId (S.bPreds b) }) succId bs2
               in (bs3, next + 1)

    rewriteSucc succId newId b =
      b { S.bTerm = rwTerm (S.bTerm b) }
      where
        rwTerm (S.TGoto t) | t == succId = S.TGoto newId
        rwTerm (S.TBr v t f)
          | t == succId = S.TBr v newId f
          | f == succId = S.TBr v t newId
          | otherwise   = S.TBr v t f
        rwTerm (S.TBrCmp inv op a b' t f)
          | t == succId = S.TBrCmp inv op a b' newId f
          | f == succId = S.TBrCmp inv op a b' t newId
          | otherwise   = S.TBrCmp inv op a b' t f
        rwTerm x = x

    replacePred old new = map (\p -> if p == old then new else p)

valToOp :: S.Value -> TAC.Operand
valToOp (S.VConst n) = TAC.OConst n
valToOp (S.VAddr l) = TAC.OAddr l
valToOp (S.VLocalAddr t) = TAC.OLocalAddr t
valToOp (S.VVar t) = TAC.OTemp t

instrToTAC :: S.Instr -> [TAC.Instr]
instrToTAC (S.IComment t) = [TAC.IComment t]
instrToTAC (S.IPhi _ _) = []
instrToTAC (S.IStore a b) = [TAC.IStore (valToOp a) (valToOp b)]
instrToTAC (S.IEffect op) =
  case op of
    S.OCall f args -> [TAC.ICall Nothing f (map valToOp args)]
    S.OAsm t       -> [TAC.IAsmInline t]
    _              -> []
instrToTAC (S.IDef dst op) =
  case op of
    S.OCopy v        -> [TAC.IAssign dst (valToOp v)]
    S.OBin bop a b   -> [TAC.IBinOp dst bop (valToOp a) (valToOp b)]
    S.OUn uop a      -> [TAC.IUnOp dst uop (valToOp a)]
    S.OLoad a        -> [TAC.ILoad dst (valToOp a)]
    S.OCall f args   -> [TAC.ICall (Just dst) f (map valToOp args)]
    S.OAsm t         -> [TAC.IAsmInline t]

termToTAC :: Map S.BlockId TAC.Label -> S.Term -> [TAC.Instr]
termToTAC lbl (S.TGoto b) =
  [TAC.IGoto (lbl Map.! b)]
termToTAC _ (S.TReturn mv) =
  [TAC.IReturn (fmap valToOp mv)]
termToTAC lbl (S.TBr v t f) =
  [ TAC.IIfNZ (valToOp v) (lbl Map.! t)
  , TAC.IGoto (lbl Map.! f)
  ]
termToTAC lbl (S.TBrCmp inv op a b t f) =
  let br = if inv then TAC.IIfNCmp op (valToOp a) (valToOp b) (lbl Map.! t)
                  else TAC.IIfCmp  op (valToOp a) (valToOp b) (lbl Map.! t)
   in [br, TAC.IGoto (lbl Map.! f)]

linearize :: Map S.BlockId S.Block -> Map S.BlockId TAC.Label -> [TAC.Instr]
linearize blocks lbl =
  concatMap one (order blocks)
  where
    order m = map snd $ Map.toAscList (Map.mapKeys S.unBlockId m)
    one b =
      let l = lbl Map.! S.bId b
          body = concatMap instrToTAC (S.bInstrs b)
          term = termToTAC lbl (S.bTerm b)
       in TAC.ILabel l : body ++ term

