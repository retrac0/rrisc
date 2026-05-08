-- | Type checking and semantic validation of the untyped AST.
module RCC.Sema
  ( CheckedProg
  , check
  , tySize
  , structFieldOffset
  , structFieldType
  ) where

import Control.Monad (when, unless)
import Control.Monad.State
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T

import RCC.Error
import qualified RCC.Syntax as Syn

-- | The checked AST.  Currently a type alias; types are re-derived in TAC.
type CheckedProg = Syn.Prog

-- ---------------------------------------------------------------------------
-- Environment

data VarEntry = VarEntry
  { veType   :: Syn.Ty
  , veConst  :: Bool
  } deriving (Show)

data Env = Env
  { envScope     :: Map Text VarEntry          -- innermost (current) scope
  , envOuter     :: [Map Text VarEntry]        -- enclosing scopes
  , envStructs   :: Map Text [Syn.Field]       -- struct definitions
  , envFuncs     :: Map Text (Syn.Ty, [(Syn.Ty, Text)])  -- name -> (retTy, params)
  , envLoopDepth :: Int
  , envRetTy     :: Syn.Ty
  } deriving (Show)

emptyEnv :: Env
emptyEnv = Env Map.empty [] Map.empty Map.empty 0 Syn.TyVoid

type M = StateT Env (Either Diagnostic)

throwAt :: Span -> Text -> M a
throwAt sp msg = lift (Left (mkError sp msg))

-- ---------------------------------------------------------------------------
-- Helpers: types and structs

tySize :: Map Text [Syn.Field] -> Syn.Ty -> Int
tySize _  Syn.TyInt          = 1
tySize _  Syn.TyUint         = 1
tySize _  Syn.TyVoid         = 0
tySize _  Syn.TyFloat        = 4
tySize _  (Syn.TyPtr _)      = 1
tySize ss (Syn.TyArray t n)  = tySize ss t * n
tySize ss (Syn.TyStruct _ n) = case Map.lookup n ss of
  Just fs -> sum (map (tySize ss . Syn.fieldTy) fs)
  Nothing -> 0   -- struct undefined: caller should have caught it earlier

structFieldOffset :: Map Text [Syn.Field] -> Text -> Text -> Maybe Int
structFieldOffset ss sname fname = do
  fs <- Map.lookup sname ss
  go 0 fs
  where
    go _ [] = Nothing
    go acc (f:fs)
      | Syn.fieldName f == fname = Just acc
      | otherwise = go (acc + tySize ss (Syn.fieldTy f)) fs

structFieldType :: Map Text [Syn.Field] -> Text -> Text -> Maybe Syn.Ty
structFieldType ss sname fname = do
  fs <- Map.lookup sname ss
  Syn.fieldTy <$> lookup fname (map (\f -> (Syn.fieldName f, f)) fs)

-- Render a type for error messages.
showTy :: Syn.Ty -> Text
showTy Syn.TyInt           = "int"
showTy Syn.TyUint          = "unsigned"
showTy Syn.TyVoid          = "void"
showTy Syn.TyFloat         = "float"
showTy (Syn.TyPtr t)       = showTy t <> " *"
showTy (Syn.TyArray t n)   = showTy t <> " [" <> T.pack (show n) <> "]"
showTy (Syn.TyStruct _ n)  = "struct " <> n

-- Span built from a single Pos.
posSp :: Pos -> Span
posSp p = Span p p

-- ---------------------------------------------------------------------------
-- Scope management

withScope :: M a -> M a
withScope action = do
  e0 <- get
  put e0 { envScope = Map.empty, envOuter = envScope e0 : envOuter e0 }
  r <- action
  e1 <- get
  put e1 { envScope = envScope e0, envOuter = envOuter e0 }
  pure r

lookupVarTy :: Text -> M (Maybe VarEntry)
lookupVarTy name = do
  env <- get
  pure $ go (envScope env : envOuter env)
  where
    go [] = Nothing
    go (s:ss) = case Map.lookup name s of
      Just v  -> Just v
      Nothing -> go ss

declareLocal :: Syn.VarDecl -> M ()
declareLocal vd = do
  env <- get
  let name = Syn.vdName vd
  case Map.lookup name (envScope env) of
    Just _ ->
      throwAt (posSp (Syn.vdNamePos vd))
        ("'" <> name <> "' already declared in this scope")
    Nothing -> do
      checkTyDefined vd
      let ve = VarEntry (Syn.vdTy vd) (Syn.vdConst vd)
      put env { envScope = Map.insert name ve (envScope env) }

-- Verify that any struct types referenced in this declaration are defined.
checkTyDefined :: Syn.VarDecl -> M ()
checkTyDefined vd = checkTy (Syn.vdTy vd)
  where
    checkTy Syn.TyInt          = pure ()
    checkTy Syn.TyUint         = pure ()
    checkTy Syn.TyVoid         = pure ()
    checkTy Syn.TyFloat        = pure ()
    checkTy (Syn.TyPtr t)      = checkTy t
    checkTy (Syn.TyArray t _)  = checkTy t
    checkTy (Syn.TyStruct sp n) = do
      env <- get
      unless (Map.member n (envStructs env)) $
        throwAt sp ("undefined struct '" <> n <> "'")

checkTyDefinedAt :: Syn.Ty -> M ()
checkTyDefinedAt Syn.TyInt          = pure ()
checkTyDefinedAt Syn.TyUint         = pure ()
checkTyDefinedAt Syn.TyVoid         = pure ()
checkTyDefinedAt Syn.TyFloat        = pure ()
checkTyDefinedAt (Syn.TyPtr t)      = checkTyDefinedAt t
checkTyDefinedAt (Syn.TyArray t _)  = checkTyDefinedAt t
checkTyDefinedAt (Syn.TyStruct sp n) = do
  env <- get
  unless (Map.member n (envStructs env)) $
    throwAt sp ("undefined struct '" <> n <> "'")

-- ---------------------------------------------------------------------------
-- Entry point

check :: Syn.Prog -> Either Diagnostic CheckedProg
check prog = do
  _ <- execStateT (checkProg prog) emptyEnv
  Right prog

checkProg :: Syn.Prog -> M ()
checkProg (Syn.Prog decls) = do
  -- Phase 1: collect struct and function declarations + global variables.
  mapM_ collectTopDecl decls
  -- Phase 2: check function bodies.
  mapM_ checkBody decls

collectTopDecl :: Syn.TopDecl -> M ()
collectTopDecl (Syn.TDStruct sd) = do
  -- Verify that field types reference defined types.
  env0 <- get
  put env0 { envStructs = Map.insert (Syn.sdName sd) (Syn.sdFields sd) (envStructs env0) }
  mapM_ (checkTyDefinedAt . Syn.fieldTy) (Syn.sdFields sd)
collectTopDecl (Syn.TDFunc fd) = do
  -- Validate parameter types.
  mapM_ (checkTyDefinedAt . fst) (Syn.fdParams fd)
  env <- get
  put env { envFuncs =
              Map.insert (Syn.fdName fd) (Syn.fdRetTy fd, Syn.fdParams fd) (envFuncs env) }
collectTopDecl (Syn.TDVar vd) = do
  -- Globals share the top-level scope.  Check redeclaration there.
  declareLocal vd
  -- Check initializer (literal range, etc.).
  case Syn.vdInit vd of
    Just (Syn.IExpr e)  -> () <$ inferExpr e
    Just (Syn.IList es) -> mapM_ (() <$) (map inferExpr es)
    Nothing             -> pure ()
collectTopDecl (Syn.TDTypedef _ _ _) = pure ()

checkBody :: Syn.TopDecl -> M ()
checkBody (Syn.TDFunc fd) = case Syn.fdBody fd of
  Nothing   -> pure ()
  Just body -> do
    env0 <- get
    put env0 { envRetTy = Syn.fdRetTy fd, envLoopDepth = 0 }
    withScope $ do
      mapM_ insertParam (Syn.fdParams fd)
      mapM_ checkStmt body
    env1 <- get
    put env1 { envRetTy = envRetTy env0, envLoopDepth = envLoopDepth env0 }
  where
    insertParam (ty, n) = do
      env <- get
      put env { envScope = Map.insert n (VarEntry ty False) (envScope env) }
checkBody _ = pure ()

-- ---------------------------------------------------------------------------
-- Statement checking

checkStmt :: Syn.Stmt -> M ()
checkStmt (Syn.SBlock _ ss) = withScope (mapM_ checkStmt ss)
checkStmt (Syn.SVarDecl vd) = do
  declareLocal vd
  case Syn.vdInit vd of
    Just (Syn.IExpr e)  -> () <$ inferExpr e
    Just (Syn.IList es) -> mapM_ (() <$) (map inferExpr es)
    Nothing             -> pure ()
checkStmt (Syn.SExpr _ e) = () <$ inferExpr e
checkStmt (Syn.SIf _ c t me) = do
  _ <- inferExpr c
  checkStmt t
  maybe (pure ()) checkStmt me
checkStmt (Syn.SWhile _ c b) = do
  _ <- inferExpr c
  inLoop (checkStmt b)
checkStmt (Syn.SFor _ ini c step b) = withScope $ do
  case ini of
    Syn.FIDecl vd       -> do declareLocal vd
                              case Syn.vdInit vd of
                                Just (Syn.IExpr e) -> () <$ inferExpr e
                                _                  -> pure ()
    Syn.FIExpr Nothing  -> pure ()
    Syn.FIExpr (Just e) -> () <$ inferExpr e
  maybe (pure ()) (\e -> () <$ inferExpr e) c
  maybe (pure ()) (\e -> () <$ inferExpr e) step
  inLoop (checkStmt b)
checkStmt (Syn.SReturn _ Nothing) = pure ()
checkStmt (Syn.SReturn _ (Just e)) = do
  env <- get
  if envRetTy env == Syn.TyVoid
    then throwAt (Syn.exprSpan e) "void function cannot return a value"
    else () <$ inferExpr e
checkStmt (Syn.SBreak sp) = do
  env <- get
  when (envLoopDepth env == 0) $
    throwAt sp "'break' outside of loop"
checkStmt (Syn.SContinue sp) = do
  env <- get
  when (envLoopDepth env == 0) $
    throwAt sp "'continue' outside of loop"
checkStmt (Syn.SAsmInline _ _) = pure ()

inLoop :: M a -> M a
inLoop action = do
  env <- get
  put env { envLoopDepth = envLoopDepth env + 1 }
  r <- action
  env' <- get
  put env' { envLoopDepth = envLoopDepth env }
  pure r

-- ---------------------------------------------------------------------------
-- Expression checking & type inference
--
-- Returns the type of the expression.  Side-effects: throws diagnostics.

inferExpr :: Syn.Expr -> M Syn.Ty
inferExpr (Syn.ELit sp n) = do
  when (n < 0 || n > 4095) $
    throwAt sp ("integer literal " <> T.pack (show n) <> " out of range (0..4095)")
  pure Syn.TyInt
inferExpr (Syn.EFloatLit _ _) = pure Syn.TyFloat
inferExpr (Syn.EVar sp name) = do
  mv <- lookupVarTy name
  case mv of
    Just ve -> pure (veType ve)
    Nothing -> do
      env <- get
      if Map.member name (envFuncs env)
        then pure Syn.TyInt   -- function name as value (rare; treat as int)
        else throwAt sp ("undeclared identifier '" <> name <> "'")
inferExpr (Syn.EUnary sp op e) = do
  t <- inferExpr e
  case op of
    Syn.UDeref -> case t of
      Syn.TyPtr inner -> pure inner
      _ -> throwAt sp ("cannot dereference non-pointer type '" <> showTy t <> "'")
    Syn.UAddrOf -> pure (Syn.TyPtr t)
    Syn.UNeg    -> pure t
    Syn.UNot    -> pure Syn.TyInt
    Syn.UBNot   -> pure t
    Syn.UPreInc -> pure t
    Syn.UPreDec -> pure t
inferExpr (Syn.EBinary sp op l r) = do
  lt <- inferExpr l
  rt <- inferExpr r
  case op of
    Syn.BAdd -> case (lt, rt) of
      (Syn.TyFloat, _) -> pure Syn.TyFloat
      (_, Syn.TyFloat) -> pure Syn.TyFloat
      _ -> case (isPtr lt, isPtr rt) of
        (True, True)  -> throwAt sp "invalid operands to '+': both operands are pointers"
        (True, False) -> pure lt
        (False, True) -> pure rt
        _             -> pure Syn.TyInt
    Syn.BSub -> case (lt, rt) of
      (Syn.TyFloat, _) -> pure Syn.TyFloat
      _ -> case (isPtr lt, isPtr rt) of
        (True, True)  -> pure Syn.TyInt
        (True, False) -> pure lt
        (False, True) -> throwAt sp "invalid operands to '-': non-pointer minus pointer"
        _             -> pure Syn.TyInt
    Syn.BMul | lt == Syn.TyFloat -> pure Syn.TyFloat
    Syn.BDiv | lt == Syn.TyFloat -> pure Syn.TyFloat
    _ -> pure Syn.TyInt
  where
    isPtr (Syn.TyPtr _) = True
    isPtr _             = False
inferExpr (Syn.EAssign _ _ lhs rhs) = do
  -- Verify LHS is assignable.
  checkLValue lhs
  lt <- inferExpr lhs
  _  <- inferExpr rhs
  pure lt
inferExpr (Syn.EIndex sp arr idx) = do
  at <- inferExpr arr
  _  <- inferExpr idx
  case at of
    Syn.TyPtr t   -> pure t
    Syn.TyArray t _ -> pure t
    _ -> throwAt sp ("cannot index non-pointer type '" <> showTy at <> "'")
inferExpr (Syn.EField sp e fname) = do
  t <- inferExpr e
  case t of
    Syn.TyStruct _ sname -> do
      env <- get
      case structFieldType (envStructs env) sname fname of
        Just ft -> pure ft
        Nothing -> throwAt sp ("struct '" <> sname <> "' has no field '" <> fname <> "'")
    _ -> throwAt sp ("'.' applied to non-struct type '" <> showTy t <> "'")
inferExpr (Syn.EArrow sp e fname) = do
  t <- inferExpr e
  case t of
    Syn.TyPtr (Syn.TyStruct _ sname) -> do
      env <- get
      case structFieldType (envStructs env) sname fname of
        Just ft -> pure ft
        Nothing -> throwAt sp ("struct '" <> sname <> "' has no field '" <> fname <> "'")
    _ -> throwAt sp ("'->' requires pointer-to-struct, got '" <> showTy t <> "'")
inferExpr (Syn.ECall sp name args) = do
  env <- get
  case Map.lookup name (envFuncs env) of
    Just (rt, _params) -> do
      mapM_ inferExpr args
      pure rt
    Nothing -> throwAt sp ("undeclared function '" <> name <> "'")
inferExpr (Syn.ECast _ ty e) = do
  _ <- inferExpr e
  pure ty
inferExpr (Syn.ESizeof _ _) = pure Syn.TyInt
inferExpr (Syn.EPostfix _ _ e) = inferExpr e
inferExpr (Syn.ETernary _ cond t f) = do
  _ <- inferExpr cond
  tt <- inferExpr t
  _  <- inferExpr f
  pure tt
inferExpr (Syn.EString _ _) = pure (Syn.TyPtr Syn.TyInt)
inferExpr (Syn.ECompoundLit sp ty es) = do
  checkTyDefinedAt ty
  mapM_ (\e -> () <$ inferExpr e) es
  case ty of
    Syn.TyVoid -> throwAt sp "compound literal cannot have void type"
    _          -> pure ty

-- Verify the expression is a valid lvalue (for assignment).
-- Reports 'assignment to const variable' if it names a const variable directly.
checkLValue :: Syn.Expr -> M ()
checkLValue (Syn.EVar sp name) = do
  mv <- lookupVarTy name
  case mv of
    Just ve | veConst ve ->
      throwAt sp ("assignment to 'const' variable '" <> name <> "'")
    Just _  -> pure ()
    Nothing -> throwAt sp ("undeclared identifier '" <> name <> "'")
checkLValue (Syn.EUnary _ Syn.UDeref _) = pure ()
checkLValue (Syn.EIndex _ _ _)          = pure ()
checkLValue (Syn.EField _ _ _)          = pure ()
checkLValue (Syn.EArrow _ _ _)          = pure ()
checkLValue e = throwAt (Syn.exprSpan e) "expression is not assignable"
