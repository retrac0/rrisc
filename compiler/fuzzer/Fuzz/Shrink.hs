{-# LANGUAGE LambdaCase #-}
-- | Structural shrinker for failing fuzzer cases.
--
-- Given a 'Program' that fails some oracle (e.g. "rcc and host produce
-- different output"), the shrinker iteratively applies small AST rewrites
-- and keeps any rewrite that still triggers a failure.  The result is a
-- much smaller reproducer that's easier to triage by hand and to commit
-- to the regression corpus.
--
-- Strategy: greedy fixed-point.  At each step we enumerate every
-- single-step rewrite of the current program (one statement removed, one
-- expression replaced by a child, …).  We try them in priority order;
-- the first one whose oracle returns @True@ becomes the new "current"
-- and the loop restarts from the top of the list.  When a full pass
-- produces no acceptable rewrite, we stop.
--
-- The oracle is allowed to be expensive (a full toolchain run); we cap
-- the total number of oracle calls per shrink session at
-- 'shrinkOracleBudget' so a pathological case doesn't run forever.
--
-- Shrink moves implemented (in priority order):
--
--   1. Drop a top-level non-main decl.
--   2. Drop a statement from any function body.
--   3. Drop the @else@ branch of an @if@.
--   4. Replace @if (e) S1 else S2@ with just @S1@ or just @S2@.
--   5. Drop a print at the end of @main@.
--   6. Replace a binary expression with one of its operands.
--   7. Replace a literal with @0@ or with @lit / 2@.
--   8. Replace a call with @0@.
--
-- New moves can be added by extending 'allShrinks'.
module Fuzz.Shrink
  ( shrinkProgram
  , shrinkOracleBudget
  ) where

import Data.IORef (IORef, atomicModifyIORef', newIORef)

import Fuzz.AST

-- ---------------------------------------------------------------------------
-- Public API

-- | Maximum number of oracle invocations allowed per shrink session.
-- Each invocation is a full toolchain run and takes ~1 s, so a budget of
-- 500 caps shrinking at ~10 minutes per case.
shrinkOracleBudget :: Int
shrinkOracleBudget = 500

-- | Greedy fixed-point shrink.  The oracle should return @True@ iff the
-- given program still triggers the failure of interest.  The original
-- program is not handed to the oracle; the caller is expected to have
-- already verified that the input fails.
shrinkProgram
  :: (Program -> IO Bool)   -- ^ does this program still fail?
  -> Program
  -> IO Program
shrinkProgram oracle p0 = do
  budget <- newIORef shrinkOracleBudget
  loop budget p0
  where
    loop :: IORef Int -> Program -> IO Program
    loop budget current = do
      let candidates = allShrinks current
      mNext <- firstAccepted budget oracle candidates
      case mNext of
        Just next -> loop budget next
        Nothing   -> pure current

-- | Try each candidate against the oracle in order; return the first
-- one that the oracle accepts.  Decrements the budget on each call;
-- returns 'Nothing' if the budget runs out or no candidate is accepted.
firstAccepted
  :: IORef Int
  -> (Program -> IO Bool)
  -> [Program]
  -> IO (Maybe Program)
firstAccepted _      _      []     = pure Nothing
firstAccepted budget oracle (c:cs) = do
  remaining <- atomicModifyIORef' budget (\n -> (n - 1, n - 1))
  if remaining < 0
    then pure Nothing
    else do
      ok <- oracle c
      if ok then pure (Just c) else firstAccepted budget oracle cs

-- ---------------------------------------------------------------------------
-- Shrink-move enumeration
--
-- Each shrink move takes the current 'Program' and returns a list of
-- candidate replacements.  The lists are concatenated in priority order;
-- earlier moves are tried first.

allShrinks :: Program -> [Program]
allShrinks p =
  concat
    [ dropTopDecl p
    , dropStatement p
    , dropElseBranch p
    , collapseIf p
    , dropPrint p
    , shrinkExprIntoSubexpr p
    , shrinkLiteral p
    , callToZero p
    ]

-- | Drop a top-level decl, except @main@.
dropTopDecl :: Program -> [Program]
dropTopDecl (Program ds) =
  [ Program (take i ds ++ drop (i + 1) ds)
  | (i, d) <- zip [0..] ds
  , not (isMain d)
  ]
  where
    isMain (TopFunc f) = fName f == "main"
    isMain _           = False

-- | Drop a statement from any function body.  We refuse to drop a
-- variable declaration that's still referenced later (the resulting
-- program would fail to compile, which the oracle would treat as a
-- spurious "failure").  As a cheap approximation we never drop 'SDecl'.
dropStatement :: Program -> [Program]
dropStatement (Program ds) =
  [ Program (replaceAt i (TopFunc f { fBody = body' }) ds)
  | (i, TopFunc f) <- zip [0..] ds
  , (_, body') <- pickDropStmt (fBody f)
  ]

pickDropStmt :: [Stmt] -> [(Stmt, [Stmt])]
pickDropStmt stmts =
  [ (s, take i stmts ++ drop (i + 1) stmts)
  | (i, s) <- zip [0..] stmts
  , not (isReturn s)
  , not (isDecl s)
  ]
  ++
  -- Recursively descend into nested compound statements.
  [ (s, replaceAt i s' stmts)
  | (i, s) <- zip [0..] stmts
  , s' <- recurseStmt s
  ]
  where
    isReturn SReturn{} = True
    isReturn _         = False
    isDecl SDecl{} = True
    isDecl _       = False

-- Produce alternative versions of a single statement with smaller bodies.
recurseStmt :: Stmt -> [Stmt]
recurseStmt = \case
  SIf c t e ->
       [SIf c t' e | (_, t') <- pickDropStmt t]
    ++ [SIf c t e' | (_, e') <- pickDropStmt e]
  SWhile c b ->
       [SWhile c b' | (_, b') <- pickDropStmt b]
  SFor i c s b ->
       [SFor i c s b' | (_, b') <- pickDropStmt b]
  SBlock b ->
       [SBlock b' | (_, b') <- pickDropStmt b]
  _ -> []

-- | Drop the @else@ branch of an @if@.
dropElseBranch :: Program -> [Program]
dropElseBranch = mapStmt $ \case
  SIf c t (_:_) -> [SIf c t []]
  _             -> []

-- | Replace @if (e) S1 else S2@ with just @S1@ (as a block) or just
-- @S2@.  We can't replace it with bare statements without flattening
-- into the parent block, which the 'mapStmt' helper isn't shaped for;
-- a 'SBlock' wrapper is fine and keeps semantics.
collapseIf :: Program -> [Program]
collapseIf = mapStmt $ \case
  SIf _ t e
    | not (null t) || not (null e) ->
        [SBlock t, SBlock e]
  _ -> []

-- | Drop the trailing @SPrint@ from main, one at a time.  Print
-- statements are usually the *only* observable behavior, so a failure
-- with fewer prints is strictly more interesting.  But we never drop
-- *all* prints: a program with no prints is uninteresting (its stdout
-- is empty on both targets and the oracle returns @False@).
dropPrint :: Program -> [Program]
dropPrint (Program ds) =
  [ Program (replaceAt i (TopFunc f { fBody = body' }) ds)
  | (i, TopFunc f) <- zip [0..] ds
  , fName f == "main"
  , let body  = fBody f
        prnts = [j | (j, SPrint _) <- zip [0..] body]
  , length prnts >= 2
  , j <- prnts
  , let body' = take j body ++ drop (j + 1) body
  ]

-- | Replace a binary expression with one of its operands.  Walks all
-- expressions in the program; for each 'EBin' / 'EUn' / 'EIndex' it
-- offers a child as a replacement.  Exception: don't lift a
-- non-side-effect-free child out of an 'EAssign' — we'd lose the
-- assignment.
shrinkExprIntoSubexpr :: Program -> [Program]
shrinkExprIntoSubexpr = mapExpr $ \case
  EBin _ a b   -> [a, b]
  EUn _ a      -> [a]
  EIndex _ i   -> [i]
  EDeref e     -> [e]
  EAddr  e     -> [e]
  EIfE _ t el  -> [t, el]
  _            -> []

-- | Replace a non-zero literal with @0@ or with @lit `div` 2@.
shrinkLiteral :: Program -> [Program]
shrinkLiteral = mapExpr $ \case
  ELit n
    | n > 1 && n `div` 2 /= n -> [ELit 0, ELit (n `div` 2)]
    | n == 1                  -> [ELit 0]
  _ -> []

-- | Replace a call with @0@.  Most calls return something, dropping the
-- call usually preserves the *shape* of the surrounding expression
-- without contributing the call's effects.
callToZero :: Program -> [Program]
callToZero = mapExpr $ \case
  ECall _ _ -> [ELit 0]
  _         -> []

-- ---------------------------------------------------------------------------
-- Generic AST traversals
--
-- 'mapExpr' / 'mapStmt' enumerate every expression / statement position
-- in the program.  For each position, the user-supplied function returns
-- a list of replacement subterms; we generate one candidate program per
-- (position, replacement) pair.

-- | For each statement in the program, produce candidate programs that
-- have that statement replaced by one of the alternatives the user
-- function returns.
mapStmt :: (Stmt -> [Stmt]) -> Program -> [Program]
mapStmt f (Program ds) =
  [ Program (replaceAt i (TopFunc fn { fBody = body' }) ds)
  | (i, TopFunc fn) <- zip [0..] ds
  , body' <- mapStmtList f (fBody fn)
  ]

mapStmtList :: (Stmt -> [Stmt]) -> [Stmt] -> [[Stmt]]
mapStmtList f stmts =
  [ replaceAt j s' stmts
  | (j, s) <- zip [0..] stmts
  , s' <- f s ++ recurseAlt s
  ]
  where
    recurseAlt = \case
      SIf c t e ->
           [SIf c t' e | t' <- mapStmtList f t]
        ++ [SIf c t e' | e' <- mapStmtList f e]
      SWhile c b -> [SWhile c b' | b' <- mapStmtList f b]
      SFor i c stp b -> [SFor i c stp b' | b' <- mapStmtList f b]
      SBlock b -> [SBlock b' | b' <- mapStmtList f b]
      _ -> []

-- | For each expression in the program, produce candidate programs that
-- have that expression replaced by one of the alternatives.
mapExpr :: (Expr -> [Expr]) -> Program -> [Program]
mapExpr f (Program ds) =
  [ Program (replaceAt i (TopFunc fn { fBody = body' }) ds)
  | (i, TopFunc fn) <- zip [0..] ds
  , body' <- mapExprStmtList f (fBody fn)
  ]

mapExprStmtList :: (Expr -> [Expr]) -> [Stmt] -> [[Stmt]]
mapExprStmtList f stmts =
  [ replaceAt j s' stmts
  | (j, s) <- zip [0..] stmts
  , s' <- mapExprStmt f s
  ]

mapExprStmt :: (Expr -> [Expr]) -> Stmt -> [Stmt]
mapExprStmt f = \case
  SDecl (VarDecl n ty (Just e)) -> [SDecl (VarDecl n ty (Just e')) | e' <- mapExprE f e]
  SDecl _ -> []
  SExpr e -> [SExpr e' | e' <- mapExprE f e]
  SIf c t e ->
       [SIf c' t e | c' <- mapExprE f c]
    ++ [SIf c t' e | t' <- mapExprStmtList f t]
    ++ [SIf c t e' | e' <- mapExprStmtList f e]
  SWhile c b ->
       [SWhile c' b | c' <- mapExprE f c]
    ++ [SWhile c b' | b' <- mapExprStmtList f b]
  SFor mInit mCond mStep b ->
       [SFor (Just (VarDecl n ty (Just e'))) mCond mStep b
       | Just (VarDecl n ty (Just e)) <- [mInit], e' <- mapExprE f e]
    ++ [SFor mInit (Just c') mStep b | Just c <- [mCond], c' <- mapExprE f c]
    ++ [SFor mInit mCond (Just s') b | Just s <- [mStep], s' <- mapExprE f s]
    ++ [SFor mInit mCond mStep b' | b' <- mapExprStmtList f b]
  SBlock b ->
       [SBlock b' | b' <- mapExprStmtList f b]
  SReturn (Just e) -> [SReturn (Just e') | e' <- mapExprE f e]
  SReturn Nothing  -> []
  SBreak     -> []
  SContinue  -> []
  SPrint e   -> [SPrint e' | e' <- mapExprE f e]

-- | For a single expression, produce all expression-level candidates:
-- the user's direct rewrites *plus* recursive rewrites of every subterm.
mapExprE :: (Expr -> [Expr]) -> Expr -> [Expr]
mapExprE f e = f e ++ recurse e
  where
    recurse = \case
      ELit _   -> []
      EVar _   -> []
      EBin op a b ->
           [EBin op a' b | a' <- mapExprE f a]
        ++ [EBin op a b' | b' <- mapExprE f b]
      EUn op a -> [EUn op a' | a' <- mapExprE f a]
      EAssign op l r ->
           -- Don't shrink the LHS, it's an lvalue.
           [EAssign op l r' | r' <- mapExprE f r]
      ECall n args ->
        [ECall n (replaceAt i a' args)
        | (i, a) <- zip [0..] args
        , a' <- mapExprE f a]
      EIndex a i ->
           [EIndex a' i | a' <- mapExprE f a]
        ++ [EIndex a i' | i' <- mapExprE f i]
      EDeref a -> [EDeref a' | a' <- mapExprE f a]
      EAddr  a -> [EAddr  a' | a' <- mapExprE f a]
      EIfE c t el ->
           [EIfE c' t el | c' <- mapExprE f c]
        ++ [EIfE c t' el | t' <- mapExprE f t]
        ++ [EIfE c t el' | el' <- mapExprE f el]

-- ---------------------------------------------------------------------------
-- Utility

replaceAt :: Int -> a -> [a] -> [a]
replaceAt n x xs = take n xs ++ [x] ++ drop (n + 1) xs
