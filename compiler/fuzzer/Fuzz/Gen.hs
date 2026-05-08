-- | Random program generator for the rcc fuzzer.
--
-- Semantic-equivalence contract (must hold for every program we emit):
--
--   * All scalar values are 12-bit @unsigned@ (range 0..4095).
--   * Comparisons return 0 or 1 directly; both compilers agree.
--   * Shifts use a literal amount in 0..11.
--   * Division and modulo are *not* generated.  rcc lowers @/@ and @%@ as
--     signed even with @unsigned@ operands, which differs from gcc when
--     the 12-bit value has its high bit set.  Until 'Codegen.emitBinOp'
--     grows an unsigned variant we steer clear.
--   * Loops have a hard iteration cap so we cannot accidentally exhaust
--     the simulator's @--maxcycle@.  This is enforced in two places: each
--     individual loop runs at most 'cfgLoopCap' iterations ('genWhile' /
--     'genFor'), and 'cfgMaxLoopDepth' bounds the nesting depth so total
--     work is bounded by @cfgLoopCap ^ cfgMaxLoopDepth@.  Both bounds are
--     load-bearing; the rsim @--maxcycle@ check is the safety net, not
--     the primary guarantee.
--   * Pointers, when used, point only into the current function's locals.
--
-- Note that we no longer sprinkle @& 0xFFF@ into the generated AST: the
-- 12-bit semantics are restored by "Fuzz.Print" in @TargetHost@ mode, so
-- the rcc input file ('TargetRcc') is left as natural C.  This is
-- important: rcc's TAC optimiser would otherwise constant-fold the masks
-- away on rcc but not on gcc, hiding the actual code paths we're trying
-- to test.
--
-- These restrictions are intentionally *narrower* than what rcc accepts:
-- the fuzzer's job is to exercise codegen, not the semantic checker.
-- Adding a new construct to the generator is the right way to widen
-- coverage; resist the urge to lift restrictions in place.
module Fuzz.Gen
  ( genProgram
  , GenConfig (..)
  , defaultConfig
  ) where

import Control.Monad (replicateM, when)
import Control.Monad.State.Strict
import Data.Text (Text)
import qualified Data.Text as T
import System.Random (StdGen, mkStdGen, randomR)

import Fuzz.AST
import Fuzz.OpMeta (allUnOps)

-- ---------------------------------------------------------------------------
-- Config

data GenConfig = GenConfig
  { cfgMaxFuncs    :: !Int   -- max user functions besides main
  , cfgMaxParams   :: !Int   -- max parameters per function
  , cfgMaxLocals   :: !Int   -- max scalar locals per function (excluding params)
  , cfgMaxStmts    :: !Int   -- soft cap on statements per block
  , cfgMaxExprDep  :: !Int   -- max expression nesting depth
  , cfgPrintCount  :: !Int   -- number of prints in main
  , cfgLoopCap     :: !Int   -- hard iteration cap embedded in every loop
  , cfgMaxLoopDep  :: !Int   -- max nested-loop depth (worst-case work is
                             --   cfgLoopCap ^ cfgMaxLoopDep cycles)
  , cfgUseArrays   :: !Bool
  , cfgUseCalls    :: !Bool
  , cfgUseLoops    :: !Bool
  } deriving (Show)

defaultConfig :: GenConfig
defaultConfig = GenConfig
  { cfgMaxFuncs    = 2   -- smaller TU avoids linker overflow on huge asm
  , cfgMaxParams   = 3
  , cfgMaxLocals   = 4
  , cfgMaxStmts    = 4
  , cfgMaxExprDep  = 2
  , cfgPrintCount  = 4
  , cfgLoopCap     = 6
  -- Small cap × shallow nesting keeps total simulator cycles bounded when
  -- loop bodies issue recursive calls.
  , cfgMaxLoopDep  = 2
  , cfgUseArrays   = True
  , cfgUseCalls    = True
  , cfgUseLoops    = True
  }

-- ---------------------------------------------------------------------------
-- Generator state

data GS = GS
  { gsCfg          :: !GenConfig
  , gsRng          :: !StdGen
  , gsLocals       :: ![(Text, Ty)]   -- locals + params currently in scope
  , gsScopeSt      :: ![Int]          -- saved lengths of gsLocals at scope entry
  , gsFuncs        :: ![FuncSig]      -- callable user-defined functions
  , gsCurFn        :: !Text
  , gsCurFirstParam :: !(Maybe Text)  -- name of the current function's first
                                      -- parameter (used as the recursion-depth
                                      -- argument by 'genExpr')
  , gsLocalN       :: !Int            -- next local id within current function
  , gsLoopLvl      :: !Int
  }

data FuncSig = FuncSig
  { sigName   :: !Text
  , sigParams :: ![(Ty, Text)]
  } deriving (Show)

type Gen = State GS

initState :: GenConfig -> StdGen -> Text -> [(Text, Ty)] -> [FuncSig] -> GS
initState cfg g name params funcs = GS
  { gsCfg           = cfg
  , gsRng           = g
  , gsLocals        = params
  , gsScopeSt       = []
  , gsFuncs         = funcs
  , gsCurFn         = name
  -- 'params' is in (name, ty) order with the leftmost C parameter at
  -- index 0 (cf. 'genFuncBodies' where we map @[(ty, n) | (ty, n) <-
  -- sigParams s]@ over the original signature).
  , gsCurFirstParam = case params of { (n, _):_ -> Just n; _ -> Nothing }
  , gsLocalN        = 0
  , gsLoopLvl       = 0
  }

-- ---------------------------------------------------------------------------
-- Random primitives

uniformR :: (Int, Int) -> Gen Int
uniformR rng = do
  s <- get
  let (n, g') = randomR rng (gsRng s)
  put s { gsRng = g' }
  pure n

oneOf :: [a] -> Gen a
oneOf xs = do
  i <- uniformR (0, length xs - 1)
  pure (xs !! i)

-- | Weighted choice.  Branches with weight 0 never fire and are safe to
-- include unconditionally.
frequency :: [(Int, Gen a)] -> Gen a
frequency choices = do
  let positive = filter ((> 0) . fst) choices
      total    = sum (map fst positive)
  when (total <= 0) $
    error "frequency: all branches have weight 0"
  i <- uniformR (1, total)
  go i positive
  where
    go _ [] = error "frequency: ran out of branches"
    go k ((w, x):xs)
      | k <= w    = x
      | otherwise = go (k - w) xs

-- ---------------------------------------------------------------------------
-- Scope helpers

pushScope :: Gen ()
pushScope = modify $ \s -> s { gsScopeSt = length (gsLocals s) : gsScopeSt s }

popScope :: Gen ()
popScope = modify $ \s ->
  case gsScopeSt s of
    (n:rest) -> s { gsLocals = drop (length (gsLocals s) - n) (gsLocals s)
                  , gsScopeSt = rest
                  }
    []       -> s

scoped :: Gen a -> Gen a
scoped m = do
  pushScope
  x <- m
  popScope
  pure x

freshLocal :: Gen Text
freshLocal = do
  s <- get
  let n = gsLocalN s
  put s { gsLocalN = n + 1 }
  pure (T.pack ('v' : show n))

addLocal :: Text -> Ty -> Gen ()
addLocal n ty = modify $ \s -> s { gsLocals = (n, ty) : gsLocals s }

-- ---------------------------------------------------------------------------
-- Top-level program

genProgram :: GenConfig -> Int -> Program
genProgram cfg seed =
  let g0 = mkStdGen seed
      -- Pick a number of user functions and their signatures up front.
      (numFuncs, g1) = randomR (0, cfgMaxFuncs cfg) g0
      (sigs, g2)     = pickSigs cfg g1 numFuncs
      (funcs, g3)    = genFuncBodies cfg sigs g2
      (mainBody, _)  = runState
                         (genMain sigs)
                         (initState cfg g3 "main" [] sigs)
      mainDecl = TopFunc FuncDecl
        { fName   = "main"
        , fParams = []
        , fBody   = mainBody ++ [SReturn (Just (ELit 0))]
        }
  in Program (map TopFunc funcs ++ [mainDecl])

pickSigs :: GenConfig -> StdGen -> Int -> ([FuncSig], StdGen)
pickSigs cfg = go (0 :: Int)
  where
    go _ g 0 = ([], g)
    go i g n =
      -- Every helper always has ≥1 parameter so the recursion-depth guard
      -- ('if (p0 >= 4) return 0') applies (nullary helpers would recurse
      -- without bound).
      let kLo     = 1
          kHi     = max kLo (cfgMaxParams cfg)
          (k, g1) = randomR (kLo, kHi) g
          name    = T.pack ('f' : show i)
          ps      = zip (replicate k TyU) [T.pack ('p' : show j) | j <- [0 .. k - 1]]
          sig     = FuncSig name ps
          (rest, g2) = go (i + 1) g1 (n - 1)
      in (sig : rest, g2)

-- Generate user functions.  Each body may call only @f0 .. fi@ (definition
-- order), never a not-yet-defined helper — this prevents unbounded mutual
-- recursion (@f0@↔@f1@) while keeping self-calls (always @fi@ itself).
-- Self-recursion is bounded by the depth-guard on @p0@.
genFuncBodies :: GenConfig -> [FuncSig] -> StdGen -> ([FuncDecl], StdGen)
genFuncBodies cfg sigs rng0 = go 0 rng0
  where
    n = length sigs
    go i rng
      | i >= n    = ([], rng)
      | otherwise =
          let s              = sigs !! i
              paramsAsLocals = [(n', ty) | (ty, n') <- sigParams s]
              visible        = take (i + 1) sigs
              st0  = (initState cfg rng (sigName s) paramsAsLocals visible)
                       { gsLocalN = 0 }
              (body, st1) = runState (genFuncBody s) st0
              (rest, rng') = go (i + 1) (gsRng st1)
          in (FuncDecl (sigName s) (sigParams s) body : rest, rng')

-- ---------------------------------------------------------------------------
-- Function bodies

genFuncBody :: FuncSig -> Gen [Stmt]
genFuncBody sig = do
  cfg <- gets gsCfg
  -- Recursion guard: if the function takes at least one parameter, its
  -- first parameter doubles as a "depth" argument.  We emit
  -- @if (p0 >= 4) return 0;@ at the very top of the body, and any
  -- recursive call (a 'ECall' to 'sigName sig' from within this body)
  -- gets its first arg replaced with @p0 + 1@ in 'genCallArg' below.
  let recGuard = case sigParams sig of
        ((_, p0) : _) ->
          [ SIf (EBin OGe (EVar p0) (ELit 4))
              [SReturn (Just (ELit 0))] [] ]
        [] -> []
  numLocals <- uniformR (0, max 0 (cfgMaxLocals cfg - 1))
  locals <- replicateM numLocals genLocalDecl
  -- Splice an early return after locals are in scope so we reference a real
  -- scalar (never hard-code @v0@ — it might be an array or absent).
  earlyRet <- frequency
    [ (4, pure [])
    , (1, do
        scalars <- gets (\s -> [n | (n, TyU) <- gsLocals s])
        if null scalars
          then pure []
          else do
            anchor <- oneOf scalars
            e <- genExpr (cfgMaxExprDep cfg)
            let cond = EBin OLt (EVar anchor) (ELit 0x100)
            pure [ SIf cond [SReturn (Just e)] [] ])
    ]
  body   <- genStmtBlock (cfgMaxStmts cfg)
  -- Every helper function returns @sum(params)@ (or a random expression
  -- when nullary).  rcc requires non-void functions to return.  The
  -- printer's host-mode mask wrappers ensure the value still fits in
  -- 12 bits when gcc evaluates it.
  retE <- if null (sigParams sig)
            then genExpr 1
            else pure $ foldr1 (EBin OAdd) (map (EVar . snd) (sigParams sig))
  pure (recGuard ++ locals ++ earlyRet ++ body ++ [SReturn (Just retE)])

genMain :: [FuncSig] -> Gen [Stmt]
genMain _sigs = do
  cfg <- gets gsCfg
  locals <- replicateM (cfgMaxLocals cfg) genLocalDecl
  warm   <- genStmtBlock (cfgMaxStmts cfg)
  prints <- replicateM (cfgPrintCount cfg)
              (SPrint <$> genExpr (cfgMaxExprDep cfg))
  pure (locals ++ warm ++ prints)

-- ---------------------------------------------------------------------------
-- Statements

genStmtBlock :: Int -> Gen [Stmt]
genStmtBlock cap = do
  n <- uniformR (1, max 1 cap)
  scoped (replicateM n genStmt)

genStmt :: Gen Stmt
genStmt = do
  cfg     <- gets gsCfg
  scalars <- gets (\s -> [n | (n, TyU) <- gsLocals s])
  loopLvl <- gets gsLoopLvl
  let inLoop      = loopLvl > 0
      -- Bound nested loops at cfgMaxLoopDep.  Without this, deep nests
      -- like @for { for { for { for { … } } } }@ run @cfgLoopCap ^ depth@
      -- iterations and trip the simulator's @--maxcycle@ guard, hiding
      -- real mismatches behind a stage failure.
      loopAllowed = cfgUseLoops cfg && loopLvl < cfgMaxLoopDep cfg
      assignW     = if null scalars then 0 else 5
      compW       = if null scalars then 0 else 2
      ifW         = 2
      whileW      = if loopAllowed then 1 else 0
      forW        = if loopAllowed then 1 else 0
      breakW      = if inLoop then 1 else 0
      -- rcc's lowered loops use a trailing tick; @continue@ would skip it
      -- and spin (rsim maxcycle).  Comma in @for(;;)@ is not in rcc.
      continueW   = 0
      blockW      = 1
      declW       = 1
      incDecW     = if null scalars then 0 else 2
  frequency
    [ (assignW,   genAssign scalars)
    , (compW,     genCompoundAssign scalars)
    , (ifW,       genIf)
    , (whileW,    genWhile)
    , (forW,      genFor)
    , (breakW,    pure SBreak)
    , (continueW, pure SContinue)
    , (blockW,    SBlock <$> genStmtBlock 3)
    , (declW,     genLocalDecl)
    , (incDecW,   genIncDecStmt scalars)
    ]

-- A standalone @x++;@, @x--;@, @++x;@, or @--x;@.  We emit only as a
-- statement, never inside a larger expression: in expression context
-- the read-then-write semantics would need 12-bit-aware lvalue masking
-- on the host, which 'Fuzz.Print' only supports at statement level.
genIncDecStmt :: [Text] -> Gen Stmt
genIncDecStmt scalars = do
  target <- oneOf scalars
  op     <- oneOf [UPreInc, UPostInc, UPreDec, UPostDec]
  pure (SExpr (EUn op (EVar target)))

-- A plain "x = expr;" assignment.  The host-mode printer wraps the RHS so
-- it stays in 12 bits; rcc gets the natural form.
genAssign :: [Text] -> Gen Stmt
genAssign scalars = do
  target <- oneOf scalars
  cfg    <- gets gsCfg
  rhs    <- genExpr (cfgMaxExprDep cfg)
  pure (SExpr (EAssign AEq (EVar target) rhs))

-- A compound assignment like "x += y;".  The printer in host mode follows
-- it with `x &= 0xFFF;` so the host's 32-bit @x@ doesn't escape the
-- 12-bit range.  On rcc the natural form is what we want.
genCompoundAssign :: [Text] -> Gen Stmt
genCompoundAssign scalars = do
  target <- oneOf scalars
  op     <- oneOf [AAdd, ASub, AMul, ABand, ABor, ABxor]
  rhs    <- genAtom
  pure (SExpr (EAssign op (EVar target) rhs))

genIf :: Gen Stmt
genIf = do
  cfg <- gets gsCfg
  c   <- genExpr (cfgMaxExprDep cfg)
  t   <- genStmtBlock (max 1 (cfgMaxStmts cfg `div` 2))
  e   <- frequency
           [ (2, pure [])
           , (1, genStmtBlock (max 1 (cfgMaxStmts cfg `div` 2)))
           ]
  pure (SIf c t e)

-- A while loop with a hard iteration cap.  The condition is
-- @(__lc < CAP) & user_cond@ which is non-short-circuiting but works
-- because both operands are 0/1 or 12-bit.  The hard-cap counter
-- @__lc@ is *not* added to the scope visible to the body, so the body
-- cannot reassign it; this makes loop termination an unconditional
-- guarantee regardless of what assignments the body picks.
genWhile :: Gen Stmt
genWhile = scoped $ do
  cfg <- gets gsCfg
  modify $ \s -> s { gsLoopLvl = gsLoopLvl s + 1 }
  cnt <- freshLocal       -- fresh name only; not added to gsLocals
  cond <- genExpr (cfgMaxExprDep cfg)
  body <- genStmtBlock (max 1 (cfgMaxStmts cfg `div` 2))
  modify $ \s -> s { gsLoopLvl = gsLoopLvl s - 1 }
  let cap = cfgLoopCap cfg
      loopCondClause = EBin OLt (EVar cnt) (ELit cap)
      tickStmt = SExpr (EAssign AEq
                          (EVar cnt)
                          (EBin OAdd (EVar cnt) (ELit 1)))
  pure $ SBlock
    [ SDecl (VarDecl cnt TyU (Just (ELit 0)))
    , SWhile (EBin OBand loopCondClause cond)
        (body ++ [tickStmt])
    ]

-- A counted for-loop with a small bounded trip count.  The induction
-- variable is in scope inside the body so the loop varies per iteration,
-- but a *hidden* @__lc@ counter — not in scope — provides the hard
-- termination guarantee in case the body reassigns the induction
-- variable to something that never reaches the cap.  Without this we
-- saw real infinite loops where the body did things like
-- @iv = arr[0]@ inside the loop.
genFor :: Gen Stmt
genFor = scoped $ do
  cfg <- gets gsCfg
  modify $ \s -> s { gsLoopLvl = gsLoopLvl s + 1 }
  iv  <- freshLocal
  addLocal iv TyU
  guardName <- freshLocal       -- fresh name only; not added to gsLocals
  cap <- uniformR (2, cfgLoopCap cfg)
  body <- genStmtBlock (max 1 (cfgMaxStmts cfg `div` 2))
  modify $ \s -> s { gsLoopLvl = gsLoopLvl s - 1 }
  let hardCap = cfgLoopCap cfg
      tickGuard = SExpr (EAssign AEq
                           (EVar guardName)
                           (EBin OAdd (EVar guardName) (ELit 1)))
  pure $ SBlock
    [ SDecl (VarDecl guardName TyU (Just (ELit 0)))
    , SFor
        (Just (VarDecl iv TyU (Just (ELit 0))))
        (Just (EBin OBand
                 (EBin OLt (EVar guardName) (ELit hardCap))
                 (EBin OLt (EVar iv) (ELit cap))))
        (Just (EAssign AEq (EVar iv) (EBin OAdd (EVar iv) (ELit 1))))
        (body ++ [tickGuard])
    ]

-- A local declaration: scalar (most common) or small array.  Initialisers
-- are masked so the var starts in 12-bit range.
genLocalDecl :: Gen Stmt
genLocalDecl = do
  cfg <- gets gsCfg
  n   <- freshLocal
  k   <- frequency
           [ (8, pure 'u')
           , (if cfgUseArrays cfg then 2 else 0, pure 'a')
           ]
  case k of
    'a' -> do
      sz <- uniformR (2, 4)
      -- Always zero-initialise so subsequent reads are well-defined.
      let v = VarDecl n (TyArr sz TyU) (Just (ELit 0))
      addLocal n (TyArr sz TyU)
      pure (SDecl v)
    _ -> do
      e <- genExpr (cfgMaxExprDep cfg)
      addLocal n TyU
      pure (SDecl (VarDecl n TyU (Just e)))

-- ---------------------------------------------------------------------------
-- Expressions

genExpr :: Int -> Gen Expr
genExpr 0 = genAtom
genExpr d = do
  cfg     <- gets gsCfg
  scalars <- gets (\s -> [n | (n, TyU) <- gsLocals s])
  arrays  <- gets (\s -> [n | (n, TyArr _ TyU) <- gsLocals s])
  funcs   <- gets gsFuncs
  let smaller = genExpr (d - 1)
      callW   = if cfgUseCalls cfg && not (null funcs) then 1 else 0
      idxW    = if not (null arrays) then 1 else 0
      varW    = if null scalars then 0 else 4
  frequency
    [ (3,     ELit <$> uniformR (0, 4095))
    , (varW,  EVar <$> oneOf scalars)
    , (5, do
        op <- pickBinOp
        a  <- smaller
        b  <- smaller
        pure (EBin op a b))
    , (1, do
        op <- pickUnOp
        a  <- smaller
        pure (EUn op a))
    , (callW, do
        sig         <- oneOf funcs
        curFn       <- gets gsCurFn
        curP0       <- gets gsCurFirstParam
        args        <- mapM (const (genExpr (max 0 (d - 1)))) (sigParams sig)
        let -- For a recursive call, replace the first argument with
            -- @p0 + 1@ so the depth guard in 'genFuncBody' eventually
            -- terminates the recursion.  @p0@ is the first parameter of
            -- the *enclosing* function, recorded in 'gsCurFirstParam'.
            args' = case (sigName sig == curFn, curP0, args) of
              (True, Just p0, _:rest) -> EBin OAdd (EVar p0) (ELit 1) : rest
              _                       -> args
        pure (ECall (sigName sig) args'))
    , (idxW, do
        a  <- oneOf arrays
        i  <- uniformR (0, 1)   -- only the first/second element: always safe
        pure (EIndex (EVar a) (ELit i)))
    , (1, do
        s <- uniformR (0, 11)
        a <- smaller
        pure (EBin OShl a (ELit s)))
    , (1, do
        s <- uniformR (0, 11)
        a <- smaller
        pure (EBin OShr a (ELit s)))
    -- Short-circuit logical ops.  Result is 0 or 1 so it fits in 12 bits.
    -- Both rcc and gcc must agree on evaluation order: if @lhs@ is 0 for
    -- @&&@ (or non-zero for @||@) the rhs must NOT execute.  We drop in
    -- side-effecting subterms occasionally to expose evaluation-order
    -- bugs: see how 'genExpr' may pick an 'EAssign' anywhere.
    , (1, do
        op <- oneOf [OAnd, OOr]
        a  <- smaller
        b  <- smaller
        pure (EBin op a b))
    -- Ternary @c ? t : e@.  Behaves like @if/else@: only one branch
    -- executes.  rcc's implementation must agree with gcc on which side
    -- effects fire.
    , (1, do
        c  <- smaller
        t  <- smaller
        e  <- smaller
        pure (EIfE c t e))
    ]

genAtom :: Gen Expr
genAtom = do
  scalars <- gets (\s -> [n | (n, TyU) <- gsLocals s])
  frequency
    [ (3, ELit <$> uniformR (0, 4095))
    , (if null scalars then 0 else 5, EVar <$> oneOf scalars)
    ]

-- | Pick a binary operator uniformly from the non-shift ops.
--
-- Shift operators are excluded here: the rest of 'genExpr' generates
-- @<<@ / @>>@ via dedicated branches that pick a literal shift amount in
-- 0..11, since both rcc and gcc disagree on the meaning of an
-- out-of-range shift count.
--
-- We deliberately use 'oneOf' (not a weighted pick) to keep the random
-- bit-consumption stable across refactors so a given seed produces the
-- same AST.  When new operator categories are added (Phase C) this will
-- become a weighted pick over 'Fuzz.OpMeta.bmGenWeight'.
pickBinOp :: Gen BinOp
pickBinOp = oneOf nonShiftBinOps
  where
    nonShiftBinOps =
      [ OAdd, OSub, OMul
      , OBand, OBor, OBxor
      , OEq, ONe, OLt, OLe, OGt, OGe
      ]

-- | Pick a unary operator uniformly from 'Fuzz.OpMeta.allUnOps'.
pickUnOp :: Gen UnOp
pickUnOp = oneOf allUnOps
