{-# LANGUAGE OverloadedStrings #-}
module RCC.Ir.SSA.Optimize
  ( normalizeCFGProg
  , simplifyCFGProg
  , dceProg
  , sccpProg
  , copyPropProg
  , branchThreadProg
  , phiSimplifyProg
  , mergeBlocksProg
  , foldEmptyBlocksProg
  , cfgShrinkProg
  , pureCSEProg
  , strengthReduceMulProg
  , tailMergeProg
  , dispatchBalanceProg
  , elimFloatCopiesProg
  , dedupeFloatRoDataProg
  , eliminateDeadCodeProg
  ) where

import Data.Either (partitionEithers)
import Data.List (foldl', nub, sort)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Set (Set)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Bits

import qualified RCC.Ir.SSA.IR as S
import qualified RCC.Ir.SSA.Prog as SP
import qualified RCC.Ir.TAC as TAC

-- ---------------------------------------------------------------------------
-- Utilities

mapProc :: (SP.SSAProc -> (SP.SSAProc, Bool)) -> SP.SSAProg -> (SP.SSAProg, Bool)
mapProc f p =
  let (ps, chs) = unzip (map f (SP.ssaProcs p))
   in (p { SP.ssaProcs = ps }, or chs)

allBlocks :: S.Func -> [S.Block]
allBlocks f = Map.elems (S.fBlocks f)

succsOf :: S.Term -> [S.BlockId]
succsOf (S.TGoto b) = nub [b]
succsOf (S.TBr _ t f) = nub [t, f]
succsOf (S.TBrCmp _ _ _ _ t f) = nub [t, f]
succsOf (S.TReturn _) = []

usesValue :: S.Value -> [Text]
usesValue (S.VVar t) = [t]
usesValue _          = []

usesOp :: S.Op -> [Text]
usesOp (S.OBin _ a b) = concatMap usesValue [a,b]
usesOp (S.OUn _ a) = usesValue a
usesOp (S.OCopy a) = usesValue a
usesOp (S.OLoad a) = usesValue a
usesOp (S.OCall _ args) = concatMap usesValue args
usesOp (S.OTargetAsm _) = []

defOfInstr :: S.Instr -> [Text]
defOfInstr (S.IPhi nm _) = [nm]
defOfInstr (S.IDef nm _) = [nm]
defOfInstr _             = []

usesInstr :: S.Instr -> [Text]
usesInstr (S.IPhi _ edges) = concatMap (usesValue . snd) edges
usesInstr (S.IDef _ op) = usesOp op
usesInstr (S.IEffect op) = usesOp op
usesInstr (S.IStore a b) = usesValue a ++ usesValue b
usesInstr (S.IComment _) = []

termUses :: S.Term -> [Text]
termUses (S.TGoto _) = []
termUses (S.TReturn mv) = maybe [] usesValue mv
termUses (S.TBr v _ _) = usesValue v
termUses (S.TBrCmp _ _ a b _ _) = usesValue a ++ usesValue b

-- ---------------------------------------------------------------------------
-- SimplifyCFG (basic, safe)

reachableBlocks :: S.Func -> Set S.BlockId
reachableBlocks f = go Set.empty [S.fEntry f]
  where
    bm = S.fBlocks f
    go seen [] = seen
    go seen (b:bs)
      | Set.member b seen = go seen bs
      | otherwise =
          let succs = maybe [] (succsOf . S.bTerm) (Map.lookup b bm)
           in go (Set.insert b seen) (succs ++ bs)

-- | Drop phi operands whose predecessor block is no longer a CFG predecessor.
-- Needed after terminator edits (e.g. branch threading): @recomputePredSucc@ updates
-- @bPreds@ but does not remove stale phi edges by itself.
alignPhisToPredsBlock :: S.Block -> S.Block
alignPhisToPredsBlock b =
  let ps = Set.fromList (S.bPreds b)
      alignInstr (S.IPhi nm edges) = S.IPhi nm [ e | e@(p, _) <- edges, Set.member p ps ]
      alignInstr i = i
   in b { S.bInstrs = map alignInstr (S.bInstrs b) }

recomputePredSucc :: Map S.BlockId S.Block -> Map S.BlockId S.Block
recomputePredSucc bm =
  let succMap = Map.map (succsOf . S.bTerm) bm
      predMap = Map.fromListWith (++) [ (s, [b]) | (b, ss) <- Map.toList succMap, s <- ss ]
      bm1 =
        Map.mapWithKey
          (\bid b ->
             b { S.bSuccs = Map.findWithDefault [] bid succMap
               , S.bPreds = Map.findWithDefault [] bid predMap
               }
          )
          bm
   in Map.map alignPhisToPredsBlock bm1

foldConstBranch :: S.Term -> S.Term
foldConstBranch (S.TBr (S.VConst 0) _ f) = S.TGoto f
foldConstBranch (S.TBr (S.VConst _) t _) = S.TGoto t
foldConstBranch (S.TBrCmp inv op (S.VConst a) (S.VConst b) t f) =
  let r = evalCmp op a b
      taken = if inv then not r else r
   in S.TGoto (if taken then t else f)
foldConstBranch x = x

evalCmp :: TAC.BinOp -> Int -> Int -> Bool
evalCmp op a b =
  case op of
    TAC.TEq  -> a == b
    TAC.TNe  -> a /= b
    TAC.TLt  -> signed12 a <  signed12 b
    TAC.TLe  -> signed12 a <= signed12 b
    TAC.TGt  -> signed12 a >  signed12 b
    TAC.TGe  -> signed12 a >= signed12 b
    TAC.TULt -> a < b
    TAC.TULe -> a <= b
    TAC.TUGt -> a > b
    TAC.TUGe -> a >= b
    _        -> False

signed12 :: Int -> Int
signed12 x = if x >= 0o4000 then x - 0o10000 else x

simplifyCFGProc :: SP.SSAProc -> (SP.SSAProc, Bool)
simplifyCFGProc sp =
  let f0 = SP.spFunc sp
      reach = reachableBlocks f0
      bm0 = S.fBlocks f0
      bm1 = Map.filterWithKey (\k _ -> Set.member k reach) bm0
      bm2 = Map.map (\b -> b { S.bTerm = foldConstBranch (S.bTerm b) }) bm1
      bm3 = recomputePredSucc bm2
      changed = Map.size bm3 /= Map.size bm0 || any termChanged (Map.elems bm2)
      f1 = f0 { S.fBlocks = bm3 }
   in (sp { SP.spFunc = f1 }, changed)
  where
    termChanged b = S.bTerm b /= foldConstBranch (S.bTerm b)

simplifyCFGProg :: SP.SSAProg -> (SP.SSAProg, Bool)
simplifyCFGProg = mapProc simplifyCFGProc

-- | CFG normalization needed by later stages: drop unreachable blocks and
-- rebuild pred/succ metadata without changing terminators.
normalizeCFGProc :: SP.SSAProc -> (SP.SSAProc, Bool)
normalizeCFGProc sp =
  let f0 = SP.spFunc sp
      reach = reachableBlocks f0
      bm0 = S.fBlocks f0
      bm1 = Map.filterWithKey (\k _ -> Set.member k reach) bm0
      bm2 = recomputePredSucc bm1
      changed = Map.size bm2 /= Map.size bm0
      f1 = f0 { S.fBlocks = bm2 }
   in (sp { SP.spFunc = f1 }, changed)

normalizeCFGProg :: SP.SSAProg -> (SP.SSAProg, Bool)
normalizeCFGProg = mapProc normalizeCFGProc

-- ---------------------------------------------------------------------------
-- Phi simplification (trivial phis -> copy defs)

isPhi :: S.Instr -> Bool
isPhi (S.IPhi _ _) = True
isPhi _             = False

phiSimplifyBlock :: S.Block -> S.Block
phiSimplifyBlock b =
  let (phis0, rest) = span isPhi (S.bInstrs b)
      psRaw = S.bPreds b
      psSet = Set.fromList psRaw
      predsUnique = nub psRaw
      simplifyPhi :: S.Instr -> Either S.Instr S.Instr
      simplifyPhi (S.IPhi nm edges) =
        let edgesF = [ (p, v) | (p, v) <- edges, Set.member p psSet ]
            vals = nub [ v | (_, v) <- edgesF ]
            oneVal =
              case vals of
                [v] -> Just v
                _ ->
                  case predsUnique of
                    [p0] ->
                      case [ v | (p, v) <- edgesF, p == p0 ] of
                        [v] -> Just v
                        _ -> Nothing
                    _ -> Nothing
         in case oneVal of
              Just v -> Right (S.IDef nm (S.OCopy v))
              Nothing -> Left (S.IPhi nm edgesF)
      simplifyPhi i = Left i
      (phis1, newDefs) = partitionEithers (map simplifyPhi phis0)
   in b { S.bInstrs = phis1 ++ newDefs ++ rest }

phiSimplifyFunc :: S.Func -> (S.Func, Bool)
phiSimplifyFunc f =
  let bm0 = S.fBlocks f
      bm1 = Map.map phiSimplifyBlock bm0
      changed = bm1 /= bm0
      bm2 = recomputePredSucc bm1
   in (f { S.fBlocks = bm2 }, changed)

phiSimplifyProc :: SP.SSAProc -> (SP.SSAProc, Bool)
phiSimplifyProc sp =
  let (f', ch) = phiSimplifyFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

phiSimplifyProg :: SP.SSAProg -> (SP.SSAProg, Bool)
phiSimplifyProg = mapProc phiSimplifyProc

-- ---------------------------------------------------------------------------
-- CFG merge: A ends TGoto B, preds(B)==[A], B has no phis -> splice A before B

substBlockId :: S.BlockId -> S.BlockId -> S.BlockId -> S.BlockId
substBlockId old new bid | bid == old = new
substBlockId _ _ bid = bid

substTermBid :: S.BlockId -> S.BlockId -> S.Term -> S.Term
substTermBid old new t =
  let sb = substBlockId old new
   in case t of
        S.TGoto x -> S.TGoto (sb x)
        S.TBr v x y -> S.TBr v (sb x) (sb y)
        S.TBrCmp inv op a b x y -> S.TBrCmp inv op a b (sb x) (sb y)
        S.TReturn mv -> S.TReturn mv

substPhiEdgesBid :: S.BlockId -> S.BlockId -> S.Instr -> S.Instr
substPhiEdgesBid old new i =
  case i of
    S.IPhi nm edges -> S.IPhi nm [ (substBlockId old new p, v) | (p, v) <- edges ]
    _ -> i

substInstrsBid :: S.BlockId -> S.BlockId -> [S.Instr] -> [S.Instr]
substInstrsBid old new = map (substPhiEdgesBid old new)

mergeAdjacentBlocksOnce :: S.Func -> (S.Func, Bool)
mergeAdjacentBlocksOnce f =
  let bm = S.fBlocks f
      entry = S.fEntry f
      -- Find A such that term(A)=TGoto B, preds(B)=[A], B has no leading phis
      candidates =
        [ (a, b)
        | (a, ba) <- Map.toList bm
        , S.TGoto b <- [S.bTerm ba]
        , b /= a
        , Just bb <- [Map.lookup b bm]
        , nub (S.bPreds bb) == [a]
        , not (any isPhi (S.bInstrs bb))
        ]
   in case candidates of
        [] -> (f, False)
        ((a, b) : _) ->
          let ba = bm Map.! a
              bb = bm Map.! b
              mergedInstrs = S.bInstrs ba ++ S.bInstrs bb
              merged =
                bb
                  { S.bInstrs = mergedInstrs
                  , S.bTerm = S.bTerm bb
                  , S.bPreds = S.bPreds ba
                  }
              bmDelA = Map.delete a (Map.insert b merged bm)
              rewriteBlk blk =
                blk
                  { S.bInstrs = substInstrsBid a b (S.bInstrs blk)
                  , S.bTerm = substTermBid a b (S.bTerm blk)
                  }
              bm1 = Map.map rewriteBlk bmDelA
              bm2 = recomputePredSucc bm1
              entry' = if entry == a then b else entry
           in (f { S.fEntry = entry', S.fBlocks = bm2 }, True)

mergeBlocksFunc :: S.Func -> (S.Func, Bool)
mergeBlocksFunc f =
  let go g =
        let (g', ch) = mergeAdjacentBlocksOnce g
         in if ch then go g' else g'
      f' = go f
   in (f', f' /= f)

mergeBlocksProc :: SP.SSAProc -> (SP.SSAProc, Bool)
mergeBlocksProc sp =
  let (f', ch) = mergeBlocksFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

mergeBlocksProg :: SP.SSAProg -> (SP.SSAProg, Bool)
mergeBlocksProg = mapProc mergeBlocksProc

-- ---------------------------------------------------------------------------
-- Fold empty blocks (no instructions, TGoto only)

foldEmptyBlocksOnce :: S.Func -> (S.Func, Bool)
foldEmptyBlocksOnce f =
  let bm = S.fBlocks f
      entry = S.fEntry f
      empties =
        [ e
        | (e, be) <- Map.toList bm
        , null (S.bInstrs be)
        , S.TGoto c <- [S.bTerm be]
        , e /= c
        ]
   in case empties of
        [] -> (f, False)
        (e : _) ->
          let be = bm Map.! e
           in case S.bTerm be of
                S.TGoto c | c /= e ->
                  let predsE = S.bPreds be
                      bmDel = Map.delete e bm
                      rewritePred blk =
                        blk { S.bTerm = substTermBid e c (S.bTerm blk) }
                      bm1 =
                        foldl'
                          ( \m p ->
                              case Map.lookup p m of
                                Nothing -> m
                                Just bp -> Map.insert p (rewritePred bp) m
                          )
                          bmDel
                          predsE
                      fixPhiPreds blk =
                        blk
                          { S.bInstrs =
                              map
                                ( \instr ->
                                    case instr of
                                      S.IPhi nm edges ->
                                        let edges1 =
                                              concatMap
                                                ( \(p, v) ->
                                                    if p == e
                                                      then [ (p', v) | p' <- predsE ]
                                                      else [(p, v)]
                                                )
                                                edges
                                            edges2 = [ (p, v) | (p, v) <- edges1, p /= e ]
                                         in S.IPhi nm edges2
                                      x -> x
                                )
                                (S.bInstrs blk)
                          }
                      bm2 = Map.map fixPhiPreds bm1
                      bm3 = recomputePredSucc bm2
                      entry' = if entry == e then c else entry
                   in (f { S.fEntry = entry', S.fBlocks = bm3 }, True)
                _ -> (f, False)

foldEmptyBlocksFunc :: S.Func -> (S.Func, Bool)
foldEmptyBlocksFunc f =
  let go g =
        let (g', ch) = foldEmptyBlocksOnce g
         in if ch then go g' else g'
      f' = go f
   in (f', f' /= f)

foldEmptyBlocksProc :: SP.SSAProc -> (SP.SSAProc, Bool)
foldEmptyBlocksProc sp =
  let (f', ch) = foldEmptyBlocksFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

foldEmptyBlocksProg :: SP.SSAProg -> (SP.SSAProg, Bool)
foldEmptyBlocksProg = mapProc foldEmptyBlocksProc

-- | Merge linear blocks, fold empty gotos, simplify phis; iterate to fixpoint.
cfgShrinkProc :: SP.SSAProc -> (SP.SSAProc, Bool)
cfgShrinkProc sp0 =
  let step sp =
        let (sp1, c1) = mergeBlocksProc sp
            (sp2, c2) = foldEmptyBlocksProc sp1
            (sp3, c3) = phiSimplifyProc sp2
         in (sp3, c1 || c2 || c3)
      go sp =
        let (spNext, ch) = step sp
         in if ch then go spNext else sp
      spDone = go sp0
   in (spDone, spDone /= sp0)

cfgShrinkProg :: SP.SSAProg -> (SP.SSAProg, Bool)
cfgShrinkProg = mapProc cfgShrinkProc

-- ---------------------------------------------------------------------------
-- DCE (SSA liveness, conservative around effects)

isEffectful :: S.Instr -> Bool
isEffectful (S.IStore _ _) = True
isEffectful (S.IEffect op) =
  case S.effectOf op of
    S.Pure -> False
    _      -> True
-- Calls (and loads/asm) are lowered as IDef, not IEffect; they must stay unless
-- proven removable, otherwise DCE drops e.g. gets/puts when the retval temp is unused.
isEffectful (S.IDef _ op) =
  case S.effectOf op of
    S.Pure -> False
    _      -> True
isEffectful _ = False

dceFunc :: S.Func -> (S.Func, Bool)
dceFunc f =
  let bm = S.fBlocks f
      -- Seed live with all term uses + all effectful instr uses, and keep effectful instrs.
      seed = Set.fromList $
        concatMap termUses (map S.bTerm (Map.elems bm))
        ++ concatMap (concatMap usesInstr . filter isEffectful . S.bInstrs) (Map.elems bm)
      -- Propagate liveness backwards through pure defs.
      live = fixpoint seed bm
      bm' = Map.map (pruneBlock live) bm
      changed = any (\bid -> S.bInstrs (bm Map.! bid) /= S.bInstrs (bm' Map.! bid)) (Map.keys bm)
   in (f { S.fBlocks = bm' }, changed)
  where
    fixpoint s bm0 =
      let s' = Set.union s (Set.fromList (concatMap (backwardUses s) (Map.elems bm0)))
       in if s' == s then s else fixpoint s' bm0

    backwardUses live0 b =
      concatMap usesInstr [ i | i <- S.bInstrs b, any (`Set.member` live0) (defOfInstr i) ]

    pruneBlock live b =
      let preds = Set.fromList (S.bPreds b)
          keep i = isEffectful i || any (`Set.member` live) (defOfInstr i)
          instrs1 = filter keep (S.bInstrs b)
          clean (S.IPhi nm edges) = S.IPhi nm [ (p,v) | (p,v) <- edges, Set.member p preds ]
          clean x = x
       in b { S.bInstrs = map clean instrs1 }

dceProc :: SP.SSAProc -> (SP.SSAProc, Bool)
dceProc sp =
  let (f', ch) = dceFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

dceProg :: SP.SSAProg -> (SP.SSAProg, Bool)
dceProg = mapProc dceProc

-- ---------------------------------------------------------------------------
-- SCCP (minimal: constants + branch reachability, no lattice for addr/mem)

data Lat = Undef | Const Int | Overdef
  deriving (Show, Eq)

joinLat :: Lat -> Lat -> Lat
joinLat Undef x = x
joinLat x Undef = x
joinLat (Const a) (Const b) | a == b = Const a
joinLat _ _ = Overdef

evalOpLat :: Map Text Lat -> S.Op -> Lat
evalOpLat env op =
  case op of
    S.OCopy v -> valLat v
    S.OUn u v ->
      case valLat v of
        Const n -> Const (mask12 (evalUn u n))
        Undef   -> Undef
        _       -> Overdef
    S.OBin bop a b ->
      case (valLat a, valLat b) of
        (Const x, Const y) -> Const (mask12 (evalBin bop x y))
        (Undef, _) -> Undef
        (_, Undef) -> Undef
        _          -> Overdef
    _ -> Overdef
  where
    valLat (S.VConst n) = Const n
    valLat (S.VVar t) = Map.findWithDefault Undef t env
    valLat _ = Overdef

mask12 :: Int -> Int
mask12 x = x .&. 0xFFF

evalUn :: TAC.UnOp -> Int -> Int
evalUn TAC.TNeg x = negate x
evalUn TAC.TNot x = if x == 0 then 1 else 0
evalUn TAC.TBNot x = xor (x .&. 0xFFF) 0xFFF

evalBin :: TAC.BinOp -> Int -> Int -> Int
evalBin op a b =
  case op of
    TAC.TAdd -> a + b
    TAC.TSub -> a - b
    TAC.TMul -> a * b
    TAC.TDiv -> if b == 0 then 0 else signed12 a `quot` signed12 b
    TAC.TMod -> if b == 0 then 0 else signed12 a `rem` signed12 b
    TAC.TBand -> a .&. b
    TAC.TBor -> a .|. b
    TAC.TBxor -> xor a b
    TAC.TShl -> shiftL a (b `mod` 12)
    TAC.TShr -> signed12 a `shiftR` (b `mod` 12)
    TAC.TUShr -> shiftR a (b `mod` 12)
    TAC.TUDiv -> if b == 0 then 0 else a `quot` b
    TAC.TUMod -> if b == 0 then 0 else a `rem` b
    TAC.TEq -> if a == b then 1 else 0
    TAC.TNe -> if a /= b then 1 else 0
    TAC.TLt -> if signed12 a < signed12 b then 1 else 0
    TAC.TLe -> if signed12 a <= signed12 b then 1 else 0
    TAC.TGt -> if signed12 a > signed12 b then 1 else 0
    TAC.TGe -> if signed12 a >= signed12 b then 1 else 0
    TAC.TULt -> if a < b then 1 else 0
    TAC.TULe -> if a <= b then 1 else 0
    TAC.TUGt -> if a > b then 1 else 0
    TAC.TUGe -> if a >= b then 1 else 0
    _ -> 0

sccpFunc :: S.Func -> (S.Func, Bool)
sccpFunc f =
  let env0 = Map.empty
      (env, reachable) = fix env0
      rewriteBlock b =
        let instrs = map (rwInstr env reachable) (S.bInstrs b)
            term = rwTerm env reachable (S.bId b) (S.bTerm b)
         in b { S.bInstrs = instrs, S.bTerm = term }
      bm' = Map.mapWithKey (\bid b -> if Set.member bid reachable then rewriteBlock b else b) bm
      f' = f { S.fBlocks = bm' }
      changed = env /= env0
   in (f', changed)
  where
    bm = S.fBlocks f
    entry = S.fEntry f
    -- SCCP must recompute reachability when branches fold to constants. The old
    -- implementation only grew 'reach', so dead successors stayed "reachable"
    -- and phis merged constants from infeasible predecessors (miscompiles).
    fix env =
      let reach = bfsReach bm entry env
          env' = propagateUntilStable reach bm
          reach' = bfsReach bm entry env'
       in if env' == env && reach' == reach then (env', reach') else fix env'

    bfsReach :: Map S.BlockId S.Block -> S.BlockId -> Map Text Lat -> Set S.BlockId
    bfsReach bm0 start envLat =
      let go seen [] = seen
          go seen (bid : q)
            | Set.member bid seen = go seen q
            | otherwise =
                case Map.lookup bid bm0 of
                  Nothing -> go seen q
                  Just b ->
                    let ss = succsTaken envLat (S.bTerm b)
                     in go (Set.insert bid seen) (ss ++ q)
       in go Set.empty [start]

    propagateUntilStable :: Set S.BlockId -> Map S.BlockId S.Block -> Map Text Lat
    propagateUntilStable reach bm0 =
      let blkOrder = sort (Set.toList reach)
          onePass e =
            foldl'
              ( \e0 bid ->
                  case Map.lookup bid bm0 of
                    Nothing -> e0
                    Just b -> foldl' (updInstr reach) e0 (S.bInstrs b)
              )
              e
              blkOrder
          go e = let e' = onePass e in if e' == e then e else go e'
       in go Map.empty

    updInstr :: Set S.BlockId -> Map Text Lat -> S.Instr -> Map Text Lat
    updInstr reach env i =
      case i of
        S.IDef nm op ->
          let v = evalOpLat env op
           in Map.insertWith joinLat nm v env
        S.IPhi nm edges ->
          let v =
                foldl'
                  joinLat
                  Undef
                  [ latOfValue env val
                  | (p, val) <- edges
                  , Set.member p reach
                  ]
           in Map.insertWith joinLat nm v env
        _ -> env

    latOfValue _ (S.VConst n) = Const n
    latOfValue env (S.VVar t) = Map.findWithDefault Undef t env
    latOfValue _ _ = Overdef

    succsTaken env term =
      case term of
        S.TGoto b -> [b]
        S.TReturn _ -> []
        S.TBr v t f' ->
          case latOfValue env v of
            Const 0 -> [f']
            Const _ -> [t]
            _ -> [t, f']
        S.TBrCmp inv op a b t f' ->
          case (latOfValue env a, latOfValue env b) of
            (Const x, Const y) ->
              let r = evalCmp op x y
                  taken = if inv then not r else r
               in [if taken then t else f']
            _ -> [t, f']

    rwInstr env _ i =
      case i of
        S.IDef nm _ ->
          case Map.lookup nm env of
            Just (Const n) -> S.IDef nm (S.OCopy (S.VConst n))
            _ -> i
        _ -> i

    rwTerm _ reach bid term =
      if not (Set.member bid reach) then term else foldConstBranch term

sccpProc :: SP.SSAProc -> (SP.SSAProc, Bool)
sccpProc sp =
  let (f', ch) = sccpFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

sccpProg :: SP.SSAProg -> (SP.SSAProg, Bool)
sccpProg = mapProc sccpProc

-- ---------------------------------------------------------------------------
-- Copy propagation/coalescing (pure OCopy chain collapse)

copyPropFunc :: S.Func -> (S.Func, Bool)
copyPropFunc f =
  let bm = S.fBlocks f
      -- Build copy map from x = copy y.
      cmap = Map.fromList
        [ (dst, src)
        | b <- Map.elems bm
        , S.IDef dst (S.OCopy (S.VVar src)) <- S.bInstrs b
        ]
      resolve x =
        case Map.lookup x cmap of
          Just y | y /= x -> resolve y
          _               -> x
      rwVal (S.VVar t) = S.VVar (resolve t)
      rwVal v = v
      rwOp op =
        case op of
          S.OCopy v -> S.OCopy (rwVal v)
          S.OUn u v -> S.OUn u (rwVal v)
          S.OBin o a b -> S.OBin o (rwVal a) (rwVal b)
          S.OLoad a -> S.OLoad (rwVal a)
          S.OCall fn args -> S.OCall fn (map rwVal args)
          S.OTargetAsm t -> S.OTargetAsm t
      rwInstr i =
        case i of
          S.IDef nm op -> S.IDef nm (rwOp op)
          S.IPhi nm edges -> S.IPhi nm [ (p, rwVal v) | (p,v) <- edges ]
          S.IEffect op -> S.IEffect (rwOp op)
          S.IStore a b -> S.IStore (rwVal a) (rwVal b)
          _ -> i
      rwTerm t =
        case t of
          S.TGoto b -> S.TGoto b
          S.TReturn mv -> S.TReturn (fmap rwVal mv)
          S.TBr v a b -> S.TBr (rwVal v) a b
          S.TBrCmp inv op a b' x y -> S.TBrCmp inv op (rwVal a) (rwVal b') x y
      bm' = Map.map (\b -> b { S.bInstrs = map rwInstr (S.bInstrs b), S.bTerm = rwTerm (S.bTerm b) }) bm
      changed = bm' /= bm
   in (f { S.fBlocks = bm' }, changed)

copyPropProg :: SP.SSAProg -> (SP.SSAProg, Bool)
copyPropProg = mapProc (\sp -> let (f',ch)=copyPropFunc (SP.spFunc sp) in (sp{SP.spFunc=f'}, ch))

-- ---------------------------------------------------------------------------
-- Pure common subexpression elimination (per-block + linear EBB chains)

data CanonVal = CVConst Int | CVVar Text | CVAddr TAC.Label | CVLocal TAC.Temp
  deriving (Eq, Ord)

cv :: S.Value -> CanonVal
cv (S.VConst n) = CVConst n
cv (S.VVar t) = CVVar t
cv (S.VAddr l) = CVAddr l
cv (S.VLocalAddr t) = CVLocal t

commutativeBin :: Set TAC.BinOp
commutativeBin =
  Set.fromList
    [ TAC.TAdd
    , TAC.TMul
    , TAC.TBand
    , TAC.TBor
    , TAC.TBxor
    , TAC.TEq
    , TAC.TNe
    ]

data CKey = CKBin TAC.BinOp CanonVal CanonVal | CKUn TAC.UnOp CanonVal | CKCopy CanonVal
  deriving (Eq, Ord)

ckeyOfPureOp :: S.Op -> Maybe CKey
ckeyOfPureOp op =
  case op of
    S.OCopy v -> Just (CKCopy (cv v))
    S.OUn u v ->
      case S.effectOf op of
        S.Pure -> Just (CKUn u (cv v))
        _ -> Nothing
    S.OBin o a b ->
      case S.effectOf op of
        S.Pure ->
          let ca = cv a
              cb = cv b
              (ca', cb') =
                if o `Set.member` commutativeBin && cb < ca
                  then (cb, ca)
                  else (ca, cb)
           in Just (CKBin o ca' cb')
        _ -> Nothing
    _ -> Nothing

resolveSubst :: Map Text Text -> Text -> Text
resolveSubst m x =
  case Map.lookup x m of
    Nothing -> x
    Just y | y == x -> x
    Just y -> resolveSubst m y

applySubstToValue :: Map Text Text -> S.Value -> S.Value
applySubstToValue m (S.VVar t) = S.VVar (resolveSubst m t)
applySubstToValue _ v = v

applySubstToOp :: Map Text Text -> S.Op -> S.Op
applySubstToOp m op =
  case op of
    S.OCopy v -> S.OCopy (applySubstToValue m v)
    S.OUn u v -> S.OUn u (applySubstToValue m v)
    S.OBin o a b -> S.OBin o (applySubstToValue m a) (applySubstToValue m b)
    S.OLoad a -> S.OLoad (applySubstToValue m a)
    S.OCall fn args -> S.OCall fn (map (applySubstToValue m) args)
    S.OTargetAsm t -> S.OTargetAsm t

applySubstToInstr :: Map Text Text -> S.Instr -> S.Instr
applySubstToInstr m i =
  case i of
    S.IDef nm op -> S.IDef nm (applySubstToOp m op)
    S.IPhi nm edges -> S.IPhi nm [ (p, applySubstToValue m v) | (p, v) <- edges ]
    S.IEffect op -> S.IEffect (applySubstToOp m op)
    S.IStore a b -> S.IStore (applySubstToValue m a) (applySubstToValue m b)
    S.IComment x -> S.IComment x

applySubstToTerm :: Map Text Text -> S.Term -> S.Term
applySubstToTerm m t =
  case t of
    S.TGoto b -> S.TGoto b
    S.TReturn mv -> S.TReturn (fmap (applySubstToValue m) mv)
    S.TBr v a b -> S.TBr (applySubstToValue m v) a b
    S.TBrCmp inv op a b x y -> S.TBrCmp inv op (applySubstToValue m a) (applySubstToValue m b) x y

cseProcessInstrList ::
  Map CKey Text ->
  [S.Instr] ->
  ([S.Instr], Map CKey Text, Map Text Text)
cseProcessInstrList env0 is0 =
  go env0 Map.empty [] is0
  where
    go env sub acc [] = (reverse acc, env, sub)
    go env sub acc (i : is) =
      case i of
        S.IDef nm op
          | Just k <- ckeyOfPureOp op ->
              case Map.lookup k env of
                Just prev ->
                  go env (Map.insert nm prev sub) acc is
                Nothing ->
                  go (Map.insert k nm env) sub (i : acc) is
        _ -> go env sub (i : acc) is

-- | Block-local CSE only (conservative; EBB chaining can change modulo semantics).
pureCSEFunc :: S.Func -> (S.Func, Bool)
pureCSEFunc f =
  let bm0 = recomputePredSucc (S.fBlocks f)
      bids = sort (Map.keys bm0)
      (bm1, subTotal) =
        foldl'
          ( \(macc, sacc) bid ->
              case Map.lookup bid macc of
                Nothing -> (macc, sacc)
                Just b ->
                  let (is', _, subB) = cseProcessInstrList Map.empty (S.bInstrs b)
                   in (Map.insert bid b { S.bInstrs = is' } macc, Map.union subB sacc)
          )
          (bm0, Map.empty)
          bids
      bm2 =
        Map.map
          ( \b ->
              b
                { S.bInstrs = map (applySubstToInstr subTotal) (S.bInstrs b)
                , S.bTerm = applySubstToTerm subTotal (S.bTerm b)
                }
          )
          bm1
      bm3 = recomputePredSucc bm2
   in (f { S.fBlocks = bm3 }, not (Map.null subTotal))

pureCSEProc :: SP.SSAProc -> (SP.SSAProc, Bool)
pureCSEProc sp =
  let (f', ch) = pureCSEFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

pureCSEProg :: SP.SSAProg -> (SP.SSAProg, Bool)
pureCSEProg = mapProc pureCSEProc

-- ---------------------------------------------------------------------------
-- Strength reduction: multiply by power-of-two -> single shift

asMulVarConst :: S.Value -> S.Value -> Maybe (Text, Int)
asMulVarConst (S.VVar x) (S.VConst k) = Just (x, mask12 k)
asMulVarConst (S.VConst k) (S.VVar x) = Just (x, mask12 k)
asMulVarConst _ _ = Nothing

-- | Power-of-two multiply -> single left shift (matches masked shift semantics).
pow2ShiftAmount :: Int -> Maybe Int
pow2ShiftAmount k
  | k <= 0 = Nothing
  | k .&. (k - 1) /= 0 = Nothing
  | otherwise = Just (countTrailingZeros k)

strengthReduceMulInInstrs :: [S.Instr] -> ([S.Instr], Bool)
strengthReduceMulInInstrs [] = ([], False)
strengthReduceMulInInstrs (i : is) =
  case i of
    S.IDef t (S.OBin TAC.TMul a b)
      | Just (xNm, k) <- asMulVarConst a b
      , Just sh <- pow2ShiftAmount k ->
          let def = S.IDef t (S.OBin TAC.TShl (S.VVar xNm) (S.VConst sh))
              (rest, ch2) = strengthReduceMulInInstrs is
           in (def : rest, True || ch2)
    _ ->
      let (rest, ch) = strengthReduceMulInInstrs is
       in (i : rest, ch)

strengthReduceMulFunc :: S.Func -> (S.Func, Bool)
strengthReduceMulFunc f =
  let bm0 = S.fBlocks f
      (bm1, ch) =
        foldl'
          ( \(macc, chAcc) (bid, b) ->
              let (is', chB) = strengthReduceMulInInstrs (S.bInstrs b)
               in (Map.insert bid b { S.bInstrs = is' } macc, chAcc || chB)
          )
          (bm0, False)
          (Map.toList bm0)
   in (f { S.fBlocks = recomputePredSucc bm1 }, ch)

strengthReduceMulProc :: SP.SSAProc -> (SP.SSAProc, Bool)
strengthReduceMulProc sp =
  let (f', ch) = strengthReduceMulFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

strengthReduceMulProg :: SP.SSAProg -> (SP.SSAProg, Bool)
strengthReduceMulProg = mapProc strengthReduceMulProc

-- ---------------------------------------------------------------------------
-- Tail merge: merge identical basic blocks (same instrs + terminator)
--
-- Fingerprint is structural (not derived Show): stable across unrelated IR
-- pretty-printing changes and ignores block metadata (preds/succs/labels).

sep :: Text
sep = "\x1E"

rec :: Text
rec = "\x1D"

blockFingerprintKey :: S.Block -> Text
blockFingerprintKey b = T.concat (map fpInstr (S.bInstrs b)) <> sep <> fpTerm (S.bTerm b)

fpBlockId :: S.BlockId -> Text
fpBlockId bid = T.pack (show (S.unBlockId bid))

fpValue :: S.Value -> Text
fpValue (S.VVar t) = "v" <> sep <> t
fpValue (S.VConst n) = "c" <> sep <> T.pack (show n)
fpValue (S.VAddr l) = "a" <> sep <> l
fpValue (S.VLocalAddr t) = "l" <> sep <> t

fpBinOp :: TAC.BinOp -> Text
fpBinOp op = "b" <> sep <> T.pack (show op)

fpUnOp :: TAC.UnOp -> Text
fpUnOp op = "u" <> sep <> T.pack (show op)

fpOp :: S.Op -> Text
fpOp (S.OBin o a b) = T.concat ["B", sep, fpBinOp o, sep, fpValue a, sep, fpValue b]
fpOp (S.OUn o a) = T.concat ["U", sep, fpUnOp o, sep, fpValue a]
fpOp (S.OCopy v) = T.concat ["C", sep, fpValue v]
fpOp (S.OLoad v) = T.concat ["L", sep, fpValue v]
fpOp (S.OCall fn args) =
  T.concat ["F", sep, fn, sep, T.intercalate rec (map fpValue args)]
fpOp (S.OTargetAsm t) = T.concat ["M", sep, t]

fpPhiEdge :: (S.BlockId, S.Value) -> Text
fpPhiEdge (bid, v) = fpBlockId bid <> sep <> fpValue v

fpInstr :: S.Instr -> Text
fpInstr (S.IPhi nm edges) =
  T.concat ["P", sep, nm, sep, T.intercalate rec (map fpPhiEdge edges), sep]
fpInstr (S.IDef nm op) = T.concat ["D", sep, nm, sep, fpOp op, sep]
fpInstr (S.IEffect op) = T.concat ["E", sep, fpOp op, sep]
fpInstr (S.IStore a b) = T.concat ["S", sep, fpValue a, sep, fpValue b, sep]
fpInstr (S.IComment t) = T.concat ["K", sep, t, sep]

fpTerm :: S.Term -> Text
fpTerm (S.TGoto b) = T.concat ["g", sep, fpBlockId b]
fpTerm (S.TReturn mv) =
  T.concat ["r", sep, maybe "0" (\v -> "1" <> sep <> fpValue v) mv]
fpTerm (S.TBr v t f) =
  T.concat ["i", sep, fpValue v, sep, fpBlockId t, sep, fpBlockId f]
fpTerm (S.TBrCmp inv op a b t f) =
  T.concat
    [ "j"
    , sep
    , if inv then "1" else "0"
    , sep
    , fpBinOp op
    , sep
    , fpValue a
    , sep
    , fpValue b
    , sep
    , fpBlockId t
    , sep
    , fpBlockId f
    ]

mergeIdenticalBlocksFunc :: S.Func -> (S.Func, Bool)
mergeIdenticalBlocksFunc f =
  let bm0 = S.fBlocks f
      groups =
        foldl'
          ( \m (bid, b) ->
              Map.insertWith (++) (blockFingerprintKey b) [bid] m
          )
          Map.empty
          (Map.toList bm0)
      merges =
        [ (minimum reps, tail (sort reps))
        | reps <- Map.elems groups
        , length reps > 1
        ]
   in case merges of
        [] -> (f, False)
        _ ->
          let f1 = foldl' (\ff (rep, dups) -> foldl' (\g bad -> redirectBlockToRep g bad rep) ff dups) f merges
           in (f1, True)

redirectBlockToRep :: S.Func -> S.BlockId -> S.BlockId -> S.Func
redirectBlockToRep f bad rep =
  let bm = S.fBlocks f
      bm1 =
        Map.map
          ( \b ->
              b
                { S.bInstrs = map (substPhiEdgesBid bad rep) (S.bInstrs b)
                , S.bTerm = substTermBid bad rep (S.bTerm b)
                }
          )
          bm
      bm2 = Map.delete bad bm1
      bm3 = recomputePredSucc bm2
      entry' = if S.fEntry f == bad then rep else S.fEntry f
   in f { S.fEntry = entry', S.fBlocks = bm3 }

tailMergeFunc :: S.Func -> (S.Func, Bool)
tailMergeFunc = mergeIdenticalBlocksFunc

tailMergeProc :: SP.SSAProc -> (SP.SSAProc, Bool)
tailMergeProc sp =
  let (f', ch) = tailMergeFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

tailMergeProg :: SP.SSAProg -> (SP.SSAProg, Bool)
tailMergeProg = mapProc tailMergeProc

-- ---------------------------------------------------------------------------
-- Dispatch: compare-chain detection (balanced lowering hook)

data CmpLink = CmpLink
  { clX :: Text
  , clFalse :: S.BlockId
  }

readCmpLink :: S.Term -> Maybe CmpLink
readCmpLink (S.TBrCmp _ _ (S.VVar x) (S.VConst _) _ f) = Just (CmpLink x f)
readCmpLink _ = Nothing

collectLinearCmpChain :: Map S.BlockId S.Block -> S.BlockId -> Maybe ([CmpLink], S.BlockId)
collectLinearCmpChain bm start =
  case Map.lookup start bm of
    Nothing -> Nothing
    Just b0 ->
      case readCmpLink (S.bTerm b0) of
        Nothing -> Nothing
        Just s0 ->
          let xv = clX s0
              walk acc bid =
                case Map.lookup bid bm of
                  Nothing -> Just (acc, bid)
                  Just b ->
                    case readCmpLink (S.bTerm b) of
                      Nothing -> Just (acc, bid)
                      Just st ->
                        if clX st /= xv
                          then Just (acc, bid)
                          else walk (acc ++ [st]) (clFalse st)
           in walk [s0] (clFalse s0)

balanceCmpChainFunc :: S.Func -> (S.Func, Bool)
balanceCmpChainFunc f = (f, False)

dispatchBalanceFunc :: S.Func -> (S.Func, Bool)
dispatchBalanceFunc f =
  case collectLinearCmpChain (S.fBlocks f) (S.fEntry f) of
        Nothing -> (f, False)
        Just (steps, _) | length steps < 4 -> (f, False)
        _ -> balanceCmpChainFunc f

dispatchBalanceProc :: SP.SSAProc -> (SP.SSAProc, Bool)
dispatchBalanceProc sp =
  let (f', ch) = dispatchBalanceFunc (SP.spFunc sp)
   in (sp { SP.spFunc = f' }, ch)

dispatchBalanceProg :: SP.SSAProg -> (SP.SSAProg, Bool)
dispatchBalanceProg = mapProc dispatchBalanceProc

-- ---------------------------------------------------------------------------
-- Branch threading (very basic: TGoto to TGoto target)
--
-- Only follow @TGoto@ through blocks with no instructions.  Chasing across
-- non-empty blocks would skip real code (e.g. @i = 0@ before a loop), producing
-- miscompiles such as an infinite loop in @float_sqrt@ at @-O1@.

jumpThruEmpty :: S.Block -> Bool
jumpThruEmpty bb = null (S.bInstrs bb)

branchThreadFunc :: S.Func -> (S.Func, Bool)
branchThreadFunc f =
  let bm = S.fBlocks f
      tgt :: S.BlockId -> S.BlockId
      tgt b =
        case Map.lookup b bm of
          Just bb
            | jumpThruEmpty bb ->
                case S.bTerm bb of
                  S.TGoto c | c /= b -> tgt c
                  _ -> b
            | otherwise -> b
          _ -> b
      rwTerm t =
        case t of
          S.TGoto b -> S.TGoto (tgt b)
          S.TBr v a b -> S.TBr v (tgt a) (tgt b)
          S.TBrCmp inv op a b' x y -> S.TBrCmp inv op a b' (tgt x) (tgt y)
          _ -> t
      bm1 = Map.map (\b -> b { S.bTerm = rwTerm (S.bTerm b) }) bm
      bm' = recomputePredSucc bm1
      changed =
        any (\bid -> S.bTerm (bm Map.! bid) /= S.bTerm (bm1 Map.! bid)) (Map.keys bm)
          || bm' /= bm
   in (f { S.fBlocks = bm' }, changed)

branchThreadProg :: SP.SSAProg -> (SP.SSAProg, Bool)
branchThreadProg = mapProc (\sp -> let (f',ch)=branchThreadFunc (SP.spFunc sp) in (sp{SP.spFunc=f'}, ch))

-- ---------------------------------------------------------------------------
-- Float copy elimination (SSA form)
--
-- Fuse  @t = fn(dst, …);  __fcopy(dst2, dst)@  into  @t = fn(dst2, …)@  when
-- @src == dst@ (the call wrote its float result through @dst@, then we copied
-- from that same address).  Only safe for helpers whose first argument is a
-- pure float *output* buffer.  Do not apply to @__ftoa@, @float_sqrt@, etc.:
-- their first argument may be read (or alias other live data); matching
-- @__fcopy(dest, &r)@ after @__ftoa(&r, buf)@ would wrongly retarget the call.

elimFloatDstFirstArgOps :: Set Text
elimFloatDstFirstArgOps =
  Set.fromList ["__fneg", "__fadd", "__fsub", "__fmul", "__fdiv", "__itof"]

elimFloatCopiesFunc :: S.Func -> (S.Func, Bool)
elimFloatCopiesFunc f =
  let bm = S.fBlocks f
      goBlock b =
        let is = S.bInstrs b
            is' = rewriteSeq is
         in (b { S.bInstrs = is' }, is' /= is)
      bm' = Map.map (fst . goBlock) bm
      ch  = any (\bid -> S.bInstrs (bm Map.! bid) /= S.bInstrs (bm' Map.! bid)) (Map.keys bm)
   in (f { S.fBlocks = bm' }, ch)
  where
    rewriteSeq (S.IDef t (S.OCall fn (dst : args)) : S.IEffect (S.OCall "__fcopy" [dst2, src]) : rest)
      | fn /= "__fcopy"
      , fn `Set.member` elimFloatDstFirstArgOps
      , src == dst =
          S.IDef t (S.OCall fn (dst2 : args)) : rest
    rewriteSeq (x:xs) = x : rewriteSeq xs
    rewriteSeq [] = []

elimFloatCopiesProg :: SP.SSAProg -> (SP.SSAProg, Bool)
elimFloatCopiesProg = mapProc (\sp -> let (f',ch)=elimFloatCopiesFunc (SP.spFunc sp) in (sp{SP.spFunc=f'}, ch))

-- ---------------------------------------------------------------------------
-- Global-only float rodata dedupe (ported from TAC)

isFloatFlit :: TAC.Global -> Bool
isFloatFlit g =
  TAC.globalConst g
    && TAC.globalSize g == 4
    && length (TAC.globalInit g) == 4
    && "_L_flit_" `T.isPrefixOf` TAC.globalName g

dedupeFloatRoDataProg :: SP.SSAProg -> (SP.SSAProg, Bool)
dedupeFloatRoDataProg prog =
  let globs0 = SP.ssaGlobals prog
      (accRev, _, rename) =
        foldl'
          ( \(acc, byInit, ren) g ->
              if isFloatFlit g
                then
                  let k = TAC.globalInit g
                      nm = TAC.globalName g
                   in case Map.lookup k byInit of
                        Just cnm -> (acc, byInit, Map.insert nm cnm ren)
                        Nothing -> (g : acc, Map.insert k nm byInit, ren)
                else (g : acc, byInit, ren)
          )
          ([], Map.empty, Map.empty)
          globs0
      globs1 = reverse accRev
      (prog1, ch1) = (prog { SP.ssaGlobals = globs1 }, length globs1 /= length globs0)
      prog2 = substAddrProg rename prog1
   in (prog2, ch1 || not (Map.null rename))

substAddrProg :: Map TAC.Label TAC.Label -> SP.SSAProg -> SP.SSAProg
substAddrProg m = mapProcOnly
  where
    mapProcOnly p =
      p { SP.ssaProcs = map (\sp -> sp { SP.spFunc = substFunc (SP.spFunc sp) }) (SP.ssaProcs p) }
    substFunc f =
      f { S.fBlocks = Map.map substBlock (S.fBlocks f) }
    substBlock b =
      b { S.bInstrs = map substInstr (S.bInstrs b)
        , S.bTerm = substTerm (S.bTerm b)
        }
    substVal (S.VAddr l) = S.VAddr (Map.findWithDefault l l m)
    substVal v = v
    substOp op =
      case op of
        S.OBin o a b -> S.OBin o (substVal a) (substVal b)
        S.OUn o a -> S.OUn o (substVal a)
        S.OCopy a -> S.OCopy (substVal a)
        S.OLoad a -> S.OLoad (substVal a)
        S.OCall fn args -> S.OCall fn (map substVal args)
        S.OTargetAsm t -> S.OTargetAsm t
    substInstr i =
      case i of
        S.IDef nm op -> S.IDef nm (substOp op)
        S.IPhi nm edges -> S.IPhi nm [ (p, substVal v) | (p,v) <- edges ]
        S.IEffect op -> S.IEffect (substOp op)
        S.IStore a b -> S.IStore (substVal a) (substVal b)
        _ -> i
    substTerm t =
      case t of
        S.TReturn mv -> S.TReturn (fmap substVal mv)
        S.TBr v a b -> S.TBr (substVal v) a b
        S.TBrCmp inv op a b x y -> S.TBrCmp inv op (substVal a) (substVal b) x y
        _ -> t

-- ---------------------------------------------------------------------------
-- Whole-program proc DCE (callgraph)

collectCallees :: S.Func -> Set TAC.Label
collectCallees f =
  Set.fromList
    [ fn
    | b <- allBlocks f
    , i <- S.bInstrs b
    , fn <- case i of
        S.IDef _ (S.OCall callee _) -> [callee]
        S.IEffect (S.OCall callee _) -> [callee]
        _ -> []
    ]

eliminateDeadCodeProg :: SP.SSAProg -> (SP.SSAProg, Bool)
eliminateDeadCodeProg prog =
  let procMap = Map.fromList [ (S.fName (SP.spFunc sp), sp) | sp <- SP.ssaProcs prog ]
      -- Reachability from `main` only.  Library TUs (e.g. rlmath.c) have no
      -- `main`; starting BFS only at "main" would drop every real procedure
      -- (undefined symbols / garbage jumps after link).  Treat every procedure
      -- as an entry when `main` is absent.
      roots =
        if Map.member "main" procMap
          then ["main"]
          else Map.keys procMap
      live = bfs Set.empty roots procMap
      procs1 = [ sp | sp <- SP.ssaProcs prog, Set.member (S.fName (SP.spFunc sp)) live ]
      changed = length procs1 /= length (SP.ssaProcs prog)
   in (prog { SP.ssaProcs = procs1 }, changed)
  where
    bfs vis [] _ = vis
    bfs vis (x:xs) mp
      | Set.member x vis = bfs vis xs mp
      | otherwise =
          case Map.lookup x mp of
            Nothing -> bfs (Set.insert x vis) xs mp
            Just sp ->
              let cs = Set.toList (collectCallees (SP.spFunc sp))
               in bfs (Set.insert x vis) (cs ++ xs) mp

