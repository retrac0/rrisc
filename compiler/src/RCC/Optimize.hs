-- | TAC optimization pipeline for RRISC.
--
-- Pass order (last applied first): eliminateDeadCode, elimFloatCopies,
-- copyPropagate, uniqConstSubst, eliminateDeadTemps, cmpBranchPeephole,
-- foldConstants, foldBranches, dedupeFloatRoData.
-- Optimization is default-on in 'rcc' because unoptimized codegen often exceeds
-- the 12-bit word-address space (4096 words); assembly then fails with immediates
-- out of range for label addresses.
module RCC.Optimize
  ( optimize
  , optimizeWhen
  ) where

import Data.Bits
import Data.List (foldl')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as T
import qualified RCC.TAC as TAC

optimize :: TAC.TACProg -> TAC.TACProg
optimize =
    dedupeFloatRoData
  . foldBranches
  . foldConstants
  . cmpBranchPeephole
  . eliminateDeadTemps
  . uniqConstSubst
  . copyPropagate
  . elimFloatCopies
  . eliminateDeadCode

-- | Apply the full 'optimize' pipeline when True; identity when False.
-- Granular / per-pass control can extend this later (e.g. record of flags).
optimizeWhen :: Bool -> TAC.TACProg -> TAC.TACProg
optimizeWhen True  = optimize
optimizeWhen False = id

-- ---------------------------------------------------------------------------
-- Unique const assignment inlining
--
-- Any temp defined exactly once as IAssign t (OConst n) is substituted on all
-- uses.  This fixes UART-style locals after copyPropagate (which clears its
-- map across labels/goto) and before DTE removes the now-redundant IAssign.

uniqConstSubst :: TAC.TACProg -> TAC.TACProg
uniqConstSubst prog = prog { TAC.tacProcs = map ucProc (TAC.tacProcs prog) }
  where
    ucProc p =
      let is = TAC.procInstrs p
          m  = uniqConstMap is
      in if Map.null m then p
         else p { TAC.procInstrs = map (substInstr m) is }

defTempsOnce :: TAC.Instr -> [TAC.Temp]
defTempsOnce (TAC.IAssign t _)         = [t]
defTempsOnce (TAC.IBinOp t _ _ _)      = [t]
defTempsOnce (TAC.IUnOp t _ _)         = [t]
defTempsOnce (TAC.ILoad t _)           = [t]
defTempsOnce (TAC.ICall (Just t) _ _)  = [t]
defTempsOnce (TAC.IAllocLocal t)       = [t]
defTempsOnce _                         = []

uniqConstMap :: [TAC.Instr] -> ConstMap
uniqConstMap instrs =
  let defCnt :: Map TAC.Temp Int
      defCnt = foldr (\i m -> foldr (\t -> Map.insertWith (+) t (1 :: Int)) m (defTempsOnce i))
                     Map.empty
                     instrs
  in Map.fromList
       [ (t, n)
       | TAC.IAssign t (TAC.OConst n) <- instrs
       , Map.lookup t defCnt == Just 1
       ]

-- ---------------------------------------------------------------------------
-- Compare+branch peephole (TAC level)
--
-- Pattern:
--   t = (a <cmp> b)
--   ifz t goto L      ==> if !(a <cmp> b) goto L
--   ifnz t goto L     ==> if  (a <cmp> b) goto L
--
-- This avoids materializing a 0/1 boolean temp that only feeds the branch,
-- which in turn removes lots of redundant load/store in the backend.

cmpBranchPeephole :: TAC.TACProg -> TAC.TACProg
cmpBranchPeephole prog = prog { TAC.tacProcs = map goProc (TAC.tacProcs prog) }
  where
    goProc p = p { TAC.procInstrs = go (TAC.procInstrs p) }

    go [] = []
    go (TAC.IBinOp t op a b : TAC.IIfZ (TAC.OTemp t2) lbl : rest)
      | t == t2, isCmpOp op
      , not (tempUsedIn t rest) =
          TAC.IIfNCmp op a b lbl : go rest
    go (TAC.IBinOp t op a b : TAC.IIfNZ (TAC.OTemp t2) lbl : rest)
      | t == t2, isCmpOp op
      , not (tempUsedIn t rest) =
          TAC.IIfCmp op a b lbl : go rest
    go (i:rest) = i : go rest

    isCmpOp o = o `elem`
      [ TAC.TEq, TAC.TNe
      , TAC.TLt, TAC.TLe, TAC.TGt, TAC.TGe
      , TAC.TULt, TAC.TULe, TAC.TUGt, TAC.TUGe
      ]

    tempUsedIn x = any (usesTemp x)

    usesTemp x instr = any isUse (ops instr)
      where
        isUse (TAC.OTemp u)      = u == x
        isUse (TAC.OLocalAddr u) = u == x
        isUse _                  = False
    ops (TAC.IAssign _ o)       = [o]
    ops (TAC.IBinOp _ _ a b)    = [a,b]
    ops (TAC.IUnOp _ _ a)       = [a]
    ops (TAC.ILoad _ o)         = [o]
    ops (TAC.IStore a b)        = [a,b]
    ops (TAC.IIfNZ o _)         = [o]
    ops (TAC.IIfZ  o _)         = [o]
    ops (TAC.ICall _ _ args)    = args
    ops (TAC.IReturn (Just o))  = [o]
    ops _                       = []

-- ---------------------------------------------------------------------------
-- Copy propagation (within straight-line code)
--
-- This shrinks TAC substantially by removing chains like:
--   t1 = ...
--   t2 = t1
--   use t2
-- which otherwise forces redundant stack load/store in the backend.

operandMentionsTemp :: TAC.Temp -> TAC.Operand -> Bool
operandMentionsTemp t (TAC.OTemp u)      = t == u
operandMentionsTemp t (TAC.OLocalAddr u) = t == u
operandMentionsTemp _ (TAC.OConst _)   = False
operandMentionsTemp _ (TAC.OAddr _)    = False

-- When t is redefined, drop copy facts that still mention the old value of t
-- (e.g. *p++ = ch lowers to orig=p; p=p+1; IStore orig ch — substituting
-- orig -> p after p is updated stores at the wrong address).
killStaleCopiesOf :: TAC.Temp -> Map TAC.Temp TAC.Operand -> Map TAC.Temp TAC.Operand
killStaleCopiesOf t =
  Map.filterWithKey (\k v -> k /= t && not (operandMentionsTemp t v))

copyPropagate :: TAC.TACProg -> TAC.TACProg
copyPropagate prog = prog { TAC.tacProcs = map cpProc (TAC.tacProcs prog) }
  where
    cpProc p = p { TAC.procInstrs = go Map.empty (TAC.procInstrs p) }

    go _  [] = []
    go env (TAC.ILabel l : xs) =
      TAC.ILabel l : go Map.empty xs
    go env (TAC.IComment c : xs) =
      TAC.IComment c : go env xs
    go env (TAC.IAsmInline a : xs) =
      TAC.IAsmInline a : go Map.empty xs
    go env (TAC.IGoto l : xs) =
      TAC.IGoto l : go Map.empty xs
    -- Conditional branches have a fall-through path; facts about temps (e.g. a
    -- local copy of the last call result) stay valid until a label/goto/return
    -- merges paths or clobbers them.
    go env (TAC.IIfZ o l : xs) =
      TAC.IIfZ (substOp env o) l : go env xs
    go env (TAC.IIfNZ o l : xs) =
      TAC.IIfNZ (substOp env o) l : go env xs
    go env (TAC.IIfCmp op a b l : xs) =
      TAC.IIfCmp op (substOp env a) (substOp env b) l : go env xs
    go env (TAC.IIfNCmp op a b l : xs) =
      TAC.IIfNCmp op (substOp env a) (substOp env b) l : go env xs
    go env (TAC.IReturn mo : xs) =
      TAC.IReturn (substMaybe env mo) : go Map.empty xs
    go env (TAC.IStore a b : xs) =
      TAC.IStore (substOp env a) (substOp env b) : go Map.empty xs
    go env (TAC.ILoad t a : xs) =
      let a' = substOp env a
          env' = killStaleCopiesOf t env
      in TAC.ILoad t a' : go env' xs
    go env (TAC.IAssign t o : xs) =
      let o' = substOp env o
          env0 = killStaleCopiesOf t env
          env' = case o' of
            TAC.OTemp u    -> Map.insert t (TAC.OTemp u) env0
            TAC.OConst n   -> Map.insert t (TAC.OConst n) env0
            _              -> env0
      in TAC.IAssign t o' : go env' xs
    go env (TAC.IUnOp t op a : xs) =
      let a' = substOp env a
      in TAC.IUnOp t op a' : go (killStaleCopiesOf t env) xs
    go env (TAC.IBinOp t op a b : xs) =
      let a' = substOp env a
          b' = substOp env b
      in TAC.IBinOp t op a' b' : go (killStaleCopiesOf t env) xs
    go env (TAC.ICall mt f args : xs) =
      let args' = map (substOp env) args
          env'  = case mt of
            Nothing -> Map.empty
            Just t  -> killStaleCopiesOf t env
      in TAC.ICall mt f args' : go env' xs
    go env (TAC.IAllocLocal t : xs) =
      TAC.IAllocLocal t : go (killStaleCopiesOf t env) xs

    substMaybe _   Nothing  = Nothing
    substMaybe env (Just o) = Just (substOp env o)

    substOp env (TAC.OTemp t) =
      case Map.lookup t env of
        Just (TAC.OTemp u) | u /= t -> TAC.OTemp u
        Just (TAC.OConst n)         -> TAC.OConst n
        _                           -> TAC.OTemp t
    substOp _   op = op

-- ---------------------------------------------------------------------------
-- Dead temp elimination (per-procedure liveness)

eliminateDeadTemps :: TAC.TACProg -> TAC.TACProg
eliminateDeadTemps prog = prog { TAC.tacProcs = map dteProc (TAC.tacProcs prog) }
  where
    dteProc p = p { TAC.procInstrs = snd (foldr step (Set.empty, []) (TAC.procInstrs p)) }

    -- In backward order, acc is the forward suffix after `instr`.  Short-circuit
    -- && / || end arms with `IAssign phiTemp …` then either `IGoto merge` or (on
    -- the false arm) fall-through to `ILabel merge`.  Naive backward DTE drops
    -- these assigns because `live` was emptied on the other path.
    -- True when this instruction sits in a straight-line suffix (fall-through
    -- of compares included) that reaches goto / label / return — so a dead-on-
    -- exit IAssign may still be needed for the next loop iteration (e.g. i=i+1
    -- before if (...) continue; goto loop).
    followedByPhiMerge :: [TAC.Instr] -> Bool
    followedByPhiMerge xs =
      case dropWhile isNoOp xs of
        (TAC.IGoto _ : _)   -> True
        (TAC.ILabel _ : _)  -> True
        (TAC.IReturn _ : _) -> True
        (TAC.IAssign _ _ : rest) -> followedByPhiMerge rest
        (TAC.IBinOp _ _ _ _ : rest) -> followedByPhiMerge rest
        (TAC.IUnOp _ _ _ : rest) -> followedByPhiMerge rest
        (TAC.ILoad _ _ : rest) -> followedByPhiMerge rest
        -- Side-effecting instructions still sit on the path to IGoto in loop bodies
        -- (e.g. *p++ = q lowers to p=p+1 then IStore — must not drop p=p+1 as dead).
        (TAC.IStore _ _ : rest) -> followedByPhiMerge rest
        (TAC.ICall _ _ _ : rest) -> followedByPhiMerge rest
        (TAC.IIfCmp _ _ _ _ : rest) -> followedByPhiMerge rest
        (TAC.IIfNCmp _ _ _ _ : rest) -> followedByPhiMerge rest
        (TAC.IIfZ _ _ : rest) -> followedByPhiMerge rest
        (TAC.IIfNZ _ _ : rest) -> followedByPhiMerge rest
        _                   -> False
      where
        isNoOp (TAC.IComment _) = True
        isNoOp _                = False

    step instr (live, acc) =
      case instr of
        -- Control-flow / side effects: keep, but update liveness from used operands.
        -- Labels and unconditional gotos do not *kill* temps by themselves; resetting
        -- liveness here caused single-pass backward DTE to drop defs (e.g. IAssign ch
        -- after getchar) that are only used on paths that re-enter straight-line code
        -- after a label.
        TAC.ILabel _        -> (live, instr : acc)
        TAC.IComment _      -> (live, instr : acc)
        TAC.IAsmInline _    -> (Set.empty, instr : acc)
        TAC.IGoto _         -> (live, instr : acc)
        TAC.IIfZ o _        -> (addUses live [o], instr : acc)
        TAC.IIfNZ o _       -> (addUses live [o], instr : acc)
        TAC.IIfCmp _ a b _  -> (addUses live [a,b], instr : acc)
        TAC.IIfNCmp _ a b _ -> (addUses live [a,b], instr : acc)
        TAC.IReturn mo      -> (addUses live (maybe [] (:[]) mo), instr : acc)
        TAC.IStore a b      -> (addUses live [a,b], instr : acc)

        -- Pure computations: drop if the defined temp is not live.
        TAC.IAssign t o
          | Set.member t live -> (addUses (Set.delete t live) [o], instr : acc)
          | followedByPhiMerge acc ->
              -- Must record uses of o even when t is not live on the exit path;
              -- otherwise we keep this assign (for merge/back-edge) but drop the
              -- instruction that defines temps in o (e.g. i=i+1 after while).
              (addUses (Set.delete t live) [o], instr : acc)
          | otherwise         -> (live, acc)
        TAC.IUnOp t _ a
          | Set.member t live -> (addUses (Set.delete t live) [a], instr : acc)
          | otherwise         -> (live, acc)
        TAC.IBinOp t _ a b
          | Set.member t live -> (addUses (Set.delete t live) [a,b], instr : acc)
          | otherwise         -> (live, acc)
        TAC.ILoad t a
          | Set.member t live -> (addUses (Set.delete t live) [a], instr : acc)
          | otherwise         -> (live, acc)

        -- Calls are side-effecting: keep the call, but drop unused return capture.
        TAC.ICall (Just t) f args
          | Set.member t live ->
              (addUses (Set.delete t live) args, instr : acc)
          | otherwise ->
              (addUses live args, TAC.ICall Nothing f args : acc)
        TAC.ICall Nothing _ args ->
              (addUses live args, instr : acc)

        -- Local allocations are only needed if their address temp is used.
        TAC.IAllocLocal t
          | Set.member t live -> (Set.delete t live, instr : acc)
          | otherwise         -> (live, acc)

    addUses s ops = foldr addUse s ops
    addUse (TAC.OTemp t)      s = Set.insert t s
    addUse (TAC.OLocalAddr t) s = Set.insert t s
    addUse _                  s = s

-- ---------------------------------------------------------------------------
-- Float copy elimination
-- Pattern: IAllocLocal t; ICall f (OLocalAddr t : args); ICall __fcopy [dst, OLocalAddr t]
-- Collapse to: ICall f (dst : args)  (also drops the IAllocLocal)

elimFloatCopies :: TAC.TACProg -> TAC.TACProg
elimFloatCopies prog = prog { TAC.tacProcs = map elimProc (TAC.tacProcs prog) }

elimProc :: TAC.Proc -> TAC.Proc
elimProc p = p { TAC.procInstrs = elim eliminable (TAC.procInstrs p) }
  where
    eliminable = findEliminableTemps (TAC.procInstrs p)

-- A local-addr temp is eliminable if OLocalAddr t appears exactly twice:
--   once as the first arg of some ICall (the float op writes its result there)
--   once as the second arg of ICall "__fcopy" (reads it as source)
findEliminableTemps :: [TAC.Instr] -> Set.Set TAC.Temp
findEliminableTemps instrs = Set.fromList
    [ t | (t, 2) <- Map.toList useCounts
        , Set.member t fcopyArgs
        , Set.member t floatDsts ]
  where
    useCounts  = Map.unionWith (+) floatDstMap fcopyArgMap
    floatDsts  = Map.keysSet floatDstMap
    floatDstMap = Map.fromListWith (+)
        [ (t, 1) | TAC.ICall _ _ (TAC.OLocalAddr t : _) <- instrs ]
    fcopyArgMap = Map.fromListWith (+)
        [ (t, 1) | TAC.ICall _ "__fcopy" [_, TAC.OLocalAddr t] <- instrs ]
    fcopyArgs   = Map.keysSet fcopyArgMap

elim :: Set.Set TAC.Temp -> [TAC.Instr] -> [TAC.Instr]
elim _   [] = []
-- Drop IAllocLocal for eliminable temps
elim eli (TAC.IAllocLocal t : rest)
    | Set.member t eli = elim eli rest
-- Collapse: ICall f (OLocalAddr t:args) followed immediately by ICall __fcopy [dst, OLocalAddr t]
elim eli (TAC.ICall mt f (TAC.OLocalAddr t : args)
        : TAC.ICall _ "__fcopy" [dst, TAC.OLocalAddr t2]
        : rest)
    | t == t2, Set.member t eli =
        TAC.ICall mt f (dst : args) : elim eli rest
elim eli (i : rest) = i : elim eli rest

-- ---------------------------------------------------------------------------

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
substInstr cm (TAC.IIfCmp op a b l)   = TAC.IIfCmp op (substOp cm a) (substOp cm b) l
substInstr cm (TAC.IIfNCmp op a b l)  = TAC.IIfNCmp op (substOp cm a) (substOp cm b) l
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
      TAC.TUDiv -> if b == 0 then 0 else a `quot` b
      TAC.TUMod -> if b == 0 then 0 else a `rem`  b
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

-- ---------------------------------------------------------------------------
-- Dead code elimination: drop procedures (and globals) unreachable from main

eliminateDeadCode :: TAC.TACProg -> TAC.TACProg
eliminateDeadCode prog =
    prog { TAC.tacProcs   = liveProcs
         , TAC.tacGlobals = liveGlobals }
  where
    liveNames   = reachableProcs prog
    liveProcs   = filter (\p -> TAC.procName p `Set.member` liveNames) (TAC.tacProcs prog)
    liveAddrRefs = Set.fromList
        [ lbl | p <- liveProcs, instr <- TAC.procInstrs p, lbl <- addrRefs instr ]
    liveGlobals = filter (\g -> TAC.globalName g `Set.member` liveAddrRefs) (TAC.tacGlobals prog)

reachableProcs :: TAC.TACProg -> Set.Set TAC.Label
reachableProcs prog = bfs Set.empty ["main"]
  where
    procMap = Map.fromList [(TAC.procName p, p) | p <- TAC.tacProcs prog]
    bfs visited [] = visited
    bfs visited (name:queue)
      | Set.member name visited = bfs visited queue
      | otherwise =
          let callees = case Map.lookup name procMap of
                Nothing -> []
                Just p  -> [lbl | TAC.ICall _ lbl _ <- TAC.procInstrs p]
          in bfs (Set.insert name visited) (callees ++ queue)

-- OAddr labels referenced in an instruction (for global liveness)
addrRefs :: TAC.Instr -> [TAC.Label]
addrRefs instr = [lbl | TAC.OAddr lbl <- ops instr]
  where
    ops (TAC.IAssign _ o)       = [o]
    ops (TAC.IBinOp _ _ a b)    = [a, b]
    ops (TAC.IUnOp _ _ a)       = [a]
    ops (TAC.ILoad _ o)         = [o]
    ops (TAC.IStore a b)        = [a, b]
    ops (TAC.IIfNZ o _)         = [o]
    ops (TAC.IIfZ  o _)         = [o]
    ops (TAC.IReturn (Just o))  = [o]
    ops (TAC.ICall _ _ args)    = args
    ops _                       = []

-- | Merge duplicate @.float@ rodata globals (same 48-bit words) produced from
-- 'EFloatLit' lowering. Identical literals in rlibc (e.g. many @0.0@ / @10.0@)
-- each became a separate label; merging shrinks the image toward the 12-bit
-- address ceiling so soft-float demos can assemble.
isFloatFlit :: TAC.Global -> Bool
isFloatFlit g =
  TAC.globalConst g
    && TAC.globalSize g == 4
    && length (TAC.globalInit g) == 4
    && "_L_flit_" `T.isPrefixOf` TAC.globalName g

substAddrOp :: Map TAC.Label TAC.Label -> TAC.Operand -> TAC.Operand
substAddrOp m (TAC.OAddr l) = TAC.OAddr (Map.findWithDefault l l m)
substAddrOp _ o             = o

substAddrInstr :: Map TAC.Label TAC.Label -> TAC.Instr -> TAC.Instr
substAddrInstr m instr = case instr of
  TAC.IAssign t op        -> TAC.IAssign t (substAddrOp m op)
  TAC.IBinOp t op a b     -> TAC.IBinOp t op (substAddrOp m a) (substAddrOp m b)
  TAC.IUnOp t op a        -> TAC.IUnOp t op (substAddrOp m a)
  TAC.ILoad t op          -> TAC.ILoad t (substAddrOp m op)
  TAC.IStore a b          -> TAC.IStore (substAddrOp m a) (substAddrOp m b)
  TAC.IIfNZ op lbl        -> TAC.IIfNZ (substAddrOp m op) lbl
  TAC.IIfZ op lbl         -> TAC.IIfZ (substAddrOp m op) lbl
  TAC.IReturn mo          -> TAC.IReturn (fmap (substAddrOp m) mo)
  TAC.ICall mt f args     -> TAC.ICall mt f (map (substAddrOp m) args)
  TAC.IIfCmp op a b lbl   -> TAC.IIfCmp op (substAddrOp m a) (substAddrOp m b) lbl
  TAC.IIfNCmp op a b lbl  -> TAC.IIfNCmp op (substAddrOp m a) (substAddrOp m b) lbl
  _                       -> instr

dedupeFloatRoData :: TAC.TACProg -> TAC.TACProg
dedupeFloatRoData prog =
  let globs0 = TAC.tacGlobals prog
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
      renProc p =
        p {TAC.procInstrs = map (substAddrInstr rename) (TAC.procInstrs p)}
   in prog
        { TAC.tacGlobals = globs1
        , TAC.tacProcs = map renProc (TAC.tacProcs prog)
        }
