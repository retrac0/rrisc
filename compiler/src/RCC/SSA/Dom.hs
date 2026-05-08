module RCC.SSA.Dom
  ( DomInfo(..)
  , computeDominators
  , dominanceFrontiers
  , domTreeChildren
  ) where

import Data.List (foldl')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set

import qualified RCC.SSA.CFG as C

data DomInfo = DomInfo
  { doms :: Map C.BlockId (Set C.BlockId)
  , idom :: Map C.BlockId C.BlockId
  } deriving (Show)

allBlocks :: C.CFG -> [C.BlockId]
allBlocks cfg = Map.keys (C.cfgBlocks cfg)

predsOf :: C.CFG -> C.BlockId -> [C.BlockId]
predsOf cfg b = C.bPreds (C.cfgBlocks cfg Map.! b)

computeDominators :: C.CFG -> DomInfo
computeDominators cfg =
  let bs = allBlocks cfg
      entry = C.cfgEntry cfg
      allSet = Set.fromList bs
      initD = Map.fromList
        [ (b, if b == entry then Set.singleton entry else allSet)
        | b <- bs
        ]
      step d =
        foldl' (upd d) d bs
      upd dOld dNew b
        | b == entry = dNew
        | otherwise =
            let ps = predsOf cfg b
                inter =
                  case ps of
                    [] -> allSet
                    (p:rest) ->
                      foldl' Set.intersection (dOld Map.! p) [dOld Map.! q | q <- rest]
                dB = Set.insert b inter
             in Map.insert b dB dNew
      fixpoint d0 =
        let d1 = step d0
         in if d1 == d0 then d0 else fixpoint d1
      dFinal = fixpoint initD
      idomMap = Map.fromList
        [ (b, immediateDom entry dFinal b)
        | b <- bs, b /= entry
        ]
   in DomInfo dFinal idomMap
  where
    immediateDom entry dMap b =
      let db = dMap Map.! b
          cands = Set.toList (Set.delete b db)
          isImm x =
            all (\y -> y == x || not (x `Set.member` (dMap Map.! y))) cands
       in case filter isImm cands of
            [x] -> x
            _   -> entry

domTreeChildren :: C.CFG -> DomInfo -> Map C.BlockId [C.BlockId]
domTreeChildren _ di =
  Map.fromListWith (++)
    [ (p, [b])
    | (b, p) <- Map.toList (idom di)
    ]

-- | Post-order on the dominator tree (children before parent) so that when
-- computing dominance frontiers, @df@ for every proper descendant is final.
domTreePostOrder :: C.CFG -> DomInfo -> [C.BlockId]
domTreePostOrder cfg di =
  let children = domTreeChildren cfg di
      entry = C.cfgEntry cfg
      go b =
        concatMap go (Map.findWithDefault [] b children) ++ [b]
      ord0 = go entry
      rest = filter (`notElem` ord0) (allBlocks cfg)
   in ord0 ++ rest

dominanceFrontiers :: C.CFG -> DomInfo -> Map C.BlockId (Set C.BlockId)
dominanceFrontiers cfg di =
  let bs = allBlocks cfg
      children = domTreeChildren cfg di
      df0 = Map.fromList [(b, Set.empty) | b <- bs]
   in foldl' (computeDF children) df0 (domTreePostOrder cfg di)
  where
    computeDF children df b =
      let succs = C.bSuccs (C.cfgBlocks cfg Map.! b)
          dfLocal =
            Set.fromList
              [ s
              | s <- succs
              , Map.lookup s (idom di) /= Just b
              ]
          dfUp =
            foldl'
              (\acc c ->
                 let dfc = Map.findWithDefault Set.empty c df
                  in Set.union acc
                       (Set.filter (\w -> Map.lookup w (idom di) /= Just b) dfc))
              Set.empty
              (Map.findWithDefault [] b children)
          dfB = Set.union dfLocal dfUp
       in Map.insert b dfB df

