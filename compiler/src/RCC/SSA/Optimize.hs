{-# LANGUAGE OverloadedStrings #-}
module RCC.SSA.Optimize
  ( normalizeCFGProg
  , simplifyCFGProg
  , dceProg
  , sccpProg
  , copyPropProg
  , branchThreadProg
  , elimFloatCopiesProg
  , dedupeFloatRoDataProg
  , eliminateDeadCodeProg
  ) where

import Data.List (foldl', nub)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Set (Set)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Bits

import qualified RCC.SSA.IR as S
import qualified RCC.SSA.Prog as SP
import qualified RCC.TAC as TAC

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
usesOp (S.OAsm _) = []

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

recomputePredSucc :: Map S.BlockId S.Block -> Map S.BlockId S.Block
recomputePredSucc bm =
  let succMap = Map.map (succsOf . S.bTerm) bm
      predMap = Map.fromListWith (++) [ (s, [b]) | (b, ss) <- Map.toList succMap, s <- ss ]
   in Map.mapWithKey
        (\bid b ->
           b { S.bSuccs = Map.findWithDefault [] bid succMap
             , S.bPreds = Map.findWithDefault [] bid predMap
             })
        bm

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
evalUn TAC.TBNot x = complement x

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
  let bm = S.fBlocks f
      env0 = Map.empty
      (env, reachable) = fix env0 (Set.singleton (S.fEntry f))
      rewriteBlock b =
        let instrs = map (rwInstr env reachable) (S.bInstrs b)
            term = rwTerm env reachable (S.bId b) (S.bTerm b)
         in b { S.bInstrs = instrs, S.bTerm = term }
      bm' = Map.mapWithKey (\bid b -> if Set.member bid reachable then rewriteBlock b else b) bm
      f' = f { S.fBlocks = bm' }
      changed = env /= env0
   in (f', changed)
  where
    fix env reach =
      let (env', reach') = foldl' step (env, reach) (Map.elems (S.fBlocks f))
       in if env' == env && reach' == reach then (env, reach) else fix env' reach'

    step (env, reach) b
      | not (Set.member (S.bId b) reach) = (env, reach)
      | otherwise =
          let env' = foldl' upd env (S.bInstrs b)
              reach' = Set.union reach (Set.fromList (succsTaken env' (S.bTerm b)))
           in (env', reach')

    upd env i =
      case i of
        S.IDef nm op ->
          let v = evalOpLat env op
           in Map.insertWith joinLat nm v env
        S.IPhi nm edges ->
          let v = foldl' joinLat Undef [ latOfValue env val | (_, val) <- edges ]
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
            _       -> [t,f']
        S.TBrCmp inv op a b t f' ->
          case (latOfValue env a, latOfValue env b) of
            (Const x, Const y) ->
              let r = evalCmp op x y
                  taken = if inv then not r else r
               in [if taken then t else f']
            _ -> [t,f']

    rwInstr env _ i =
      case i of
        S.IDef nm _ ->
          case Map.lookup nm env of
            Just (Const n) -> S.IDef nm (S.OCopy (S.VConst n))
            _              -> i
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
          S.OAsm t -> S.OAsm t
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
-- Branch threading (very basic: TGoto to TGoto target)

branchThreadFunc :: S.Func -> (S.Func, Bool)
branchThreadFunc f =
  let bm = S.fBlocks f
      tgt :: S.BlockId -> S.BlockId
      tgt b =
        case Map.lookup b bm of
          Just bb ->
            case S.bTerm bb of
              S.TGoto c | c /= b -> tgt c
              _ -> b
          _ -> b
      rwTerm t =
        case t of
          S.TGoto b -> S.TGoto (tgt b)
          S.TBr v a b -> S.TBr v (tgt a) (tgt b)
          S.TBrCmp inv op a b' x y -> S.TBrCmp inv op a b' (tgt x) (tgt y)
          _ -> t
      bm' = Map.map (\b -> b { S.bTerm = rwTerm (S.bTerm b) }) bm
      changed = any (\bid -> S.bTerm (bm Map.! bid) /= S.bTerm (bm' Map.! bid)) (Map.keys bm)
   in (f { S.fBlocks = bm' }, changed)

branchThreadProg :: SP.SSAProg -> (SP.SSAProg, Bool)
branchThreadProg = mapProc (\sp -> let (f',ch)=branchThreadFunc (SP.spFunc sp) in (sp{SP.spFunc=f'}, ch))

-- ---------------------------------------------------------------------------
-- Float copy elimination (SSA form)

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
        S.OAsm t -> S.OAsm t
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
      live = bfs Set.empty ["main"] procMap
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

