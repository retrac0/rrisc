module RCC.TAC
  ( Temp
  , Label
  , Operand(..)
  , BinOp(..)
  , UnOp(..)
  , Instr(..)
  , Proc(..)
  , Global(..)
  , TACProg(..)
  , lower
  ) where

import Control.Monad (when, unless)
import Control.Monad.State
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T

import qualified RCC.Sema as Sema
import qualified RCC.Syntax as Syn

-- ---------------------------------------------------------------------------
-- IR types

type Temp  = Text   -- temporary or named variable
type Label = Text   -- branch target

data Operand
  = OTemp      Temp
  | OConst     Int
  | OAddr      Label   -- address-of a global label
  | OLocalAddr Temp    -- address of a local variable's stack slot
  deriving (Show, Eq)

data BinOp
  = TAdd | TSub | TMul | TDiv | TMod
  | TAnd | TOr
  | TBand | TBor | TBxor
  | TShl | TShr
  | TEq | TNe | TLt | TLe | TGt | TGe
  | TULt | TULe | TUGt | TUGe  -- unsigned comparisons
  | TUShr                        -- logical (unsigned) right shift
  deriving (Show, Eq)

data UnOp
  = TNeg | TNot | TBNot
  deriving (Show, Eq)

data Instr
  = ILabel   Label
  | IComment Text                    -- source-level annotation (emitted as ;; in asm)
  | IAssign  Temp Operand
  | IBinOp   Temp BinOp Operand Operand
  | IUnOp    Temp UnOp  Operand
  | ILoad    Temp Operand            -- t = *op
  | IStore   Operand Operand         -- *addr = val
  | IGoto    Label
  | IIfNZ    Operand Label
  | IIfZ     Operand Label
  | ICall    (Maybe Temp) Label [Operand]
  | IReturn  (Maybe Operand)
  deriving (Show)

data Global = Global
  { globalName  :: Label
  , globalSize  :: Int
  , globalInit  :: [Int]
  , globalConst :: Bool
  } deriving (Show)

data Proc = Proc
  { procName   :: Label
  , procParams :: [Temp]
  , procInstrs :: [Instr]
  } deriving (Show)

data TACProg = TACProg
  { tacGlobals :: [Global]
  , tacProcs   :: [Proc]
  } deriving (Show)

-- ---------------------------------------------------------------------------
-- Lowering monad

data LS = LS
  { lsTemp        :: Int
  , lsLabel       :: Int
  , lsInstrs      :: [Instr]                            -- reversed
  , lsLocals      :: Map Text Syn.Ty                    -- current func locals + params
  , lsGlobals     :: Map Text (Syn.Ty, Bool)
  , lsStructs     :: Map Text [Syn.Field]
  , lsFuncs       :: Map Text (Syn.Ty, [(Syn.Ty, Text)])
  , lsLoopStack   :: [(Label, Label)]                   -- (continue, break)
  , lsProcs       :: [Proc]                             -- reversed
  , lsGlobalDefs  :: [Global]                           -- reversed
  }

emptyLS :: LS
emptyLS = LS 0 0 [] Map.empty Map.empty Map.empty Map.empty [] [] []

type L = State LS

emit :: Instr -> L ()
emit i = modify $ \s -> s { lsInstrs = i : lsInstrs s }

freshTemp :: L Temp
freshTemp = do
  n <- gets lsTemp
  modify $ \s -> s { lsTemp = n + 1 }
  pure $ "%t" <> T.pack (show n)

freshLabel :: Text -> L Label
freshLabel base = do
  n <- gets lsLabel
  modify $ \s -> s { lsLabel = n + 1 }
  pure $ "_L_" <> base <> "_" <> T.pack (show n)

isLocal :: Text -> L Bool
isLocal name = Map.member name <$> gets lsLocals

isGlobal :: Text -> L Bool
isGlobal name = Map.member name <$> gets lsGlobals

addLocal :: Text -> Syn.Ty -> L ()
addLocal name ty =
  modify $ \s -> s { lsLocals = Map.insert name ty (lsLocals s) }

structOffset :: Text -> Text -> L Int
structOffset sname fname = do
  ss <- gets lsStructs
  case Sema.structFieldOffset ss sname fname of
    Just o  -> pure o
    Nothing -> pure 0

structFieldTy :: Text -> Text -> L Syn.Ty
structFieldTy sname fname = do
  ss <- gets lsStructs
  case Sema.structFieldType ss sname fname of
    Just t  -> pure t
    Nothing -> pure Syn.TyInt

-- ---------------------------------------------------------------------------
-- Top-level

lower :: Sema.CheckedProg -> TACProg
lower (Syn.Prog decls) =
  let final = execState (lowerProg decls) emptyLS
  in TACProg (reverse (lsGlobalDefs final)) (reverse (lsProcs final))

lowerProg :: [Syn.TopDecl] -> L ()
lowerProg decls = do
  mapM_ collectTop decls
  mapM_ lowerTop decls

collectTop :: Syn.TopDecl -> L ()
collectTop (Syn.TDStruct sd) =
  modify $ \s -> s { lsStructs = Map.insert (Syn.sdName sd) (Syn.sdFields sd) (lsStructs s) }
collectTop (Syn.TDFunc fd) =
  modify $ \s -> s { lsFuncs = Map.insert (Syn.fdName fd)
                                          (Syn.fdRetTy fd, Syn.fdParams fd)
                                          (lsFuncs s) }
collectTop (Syn.TDVar vd) = do
  ss <- gets lsStructs
  let name    = Syn.vdName vd
      ty      = Syn.vdTy vd
      sz      = Sema.tySize ss ty
      isC     = Syn.vdConst vd
      initVals = case Syn.vdInit vd of
        Just (Syn.IExpr e)  -> [evalConst e]
        Just (Syn.IList es) -> map evalConst es
        Nothing             -> []
  modify $ \s -> s { lsGlobals    = Map.insert name (ty, isC) (lsGlobals s)
                   , lsGlobalDefs = Global name sz initVals isC : lsGlobalDefs s }
  where
    evalConst (Syn.ELit _ n) = n
    evalConst _              = 0
collectTop _ = pure ()

lowerTop :: Syn.TopDecl -> L ()
lowerTop (Syn.TDFunc fd) = case Syn.fdBody fd of
  Nothing   -> pure ()
  Just body -> do
    s0 <- get
    put s0 { lsTemp = 0, lsInstrs = [], lsLocals = Map.empty, lsLoopStack = [] }
    mapM_ (\(ty, n) -> addLocal n ty) (Syn.fdParams fd)
    mapM_ lowerStmt body
    -- Implicit return at end of body (0 if int, void otherwise).
    sf <- get
    let alreadyReturned = case lsInstrs sf of
          (IReturn _ : _) -> True
          _               -> False
    unless alreadyReturned $ do
      if Syn.fdRetTy fd == Syn.TyVoid
        then emit (IReturn Nothing)
        else emit (IReturn (Just (OConst 0)))
    sg <- get
    let proc = Proc (Syn.fdName fd) (map snd (Syn.fdParams fd)) (reverse (lsInstrs sg))
    put sg { lsTemp        = lsTemp s0
           , lsInstrs      = lsInstrs s0
           , lsLocals      = lsLocals s0
           , lsLoopStack   = lsLoopStack s0
           , lsProcs       = proc : lsProcs sg
           }
lowerTop _ = pure ()

-- ---------------------------------------------------------------------------
-- Statements

lowerStmt :: Syn.Stmt -> L ()
lowerStmt (Syn.SBlock _ ss)   = mapM_ lowerStmt ss
lowerStmt s@(Syn.SVarDecl vd) = do
  emit (IComment (prettyStmt s))
  let name = Syn.vdName vd
      ty   = Syn.vdTy vd
  addLocal name ty
  case Syn.vdInit vd of
    Nothing            -> pure ()
    Just (Syn.IExpr e) -> do
      v <- lowerExpr e
      emit (IAssign name v)
    Just (Syn.IList _) -> pure ()  -- array initializers not supported for locals
lowerStmt s@(Syn.SExpr _ e)   = do
  emit (IComment (prettyStmt s))
  () <$ lowerExpr e
lowerStmt s@(Syn.SIf _ c t me) = do
  emit (IComment (prettyStmt s))
  cv <- lowerExpr c
  case me of
    Nothing -> do
      lEnd <- freshLabel "endif"
      emit (IIfZ cv lEnd)
      lowerStmt t
      emit (ILabel lEnd)
    Just el -> do
      lElse <- freshLabel "else"
      lEnd  <- freshLabel "endif"
      emit (IIfZ cv lElse)
      lowerStmt t
      emit (IGoto lEnd)
      emit (ILabel lElse)
      lowerStmt el
      emit (ILabel lEnd)
lowerStmt s@(Syn.SWhile _ c body) = do
  emit (IComment (prettyStmt s))
  lHead <- freshLabel "while"
  lEnd  <- freshLabel "endwhile"
  emit (ILabel lHead)
  cv <- lowerExpr c
  emit (IIfZ cv lEnd)
  pushLoop (lHead, lEnd)
  lowerStmt body
  popLoop
  emit (IGoto lHead)
  emit (ILabel lEnd)
lowerStmt s@(Syn.SFor _ ini c step body) = do
  emit (IComment (prettyStmt s))
  case ini of
    Syn.FIDecl vd -> lowerStmt (Syn.SVarDecl vd)
    Syn.FIExpr Nothing -> pure ()
    Syn.FIExpr (Just e) -> () <$ lowerExpr e
  lHead <- freshLabel "for"
  lCont <- freshLabel "forcont"
  lEnd  <- freshLabel "endfor"
  emit (ILabel lHead)
  case c of
    Nothing -> pure ()
    Just ce -> do
      cv <- lowerExpr ce
      emit (IIfZ cv lEnd)
  pushLoop (lCont, lEnd)
  lowerStmt body
  popLoop
  emit (ILabel lCont)
  case step of
    Nothing -> pure ()
    Just se -> () <$ lowerExpr se
  emit (IGoto lHead)
  emit (ILabel lEnd)
lowerStmt s@(Syn.SReturn _ Nothing) = do
  emit (IComment (prettyStmt s))
  emit (IReturn Nothing)
lowerStmt s@(Syn.SReturn _ (Just e)) = do
  emit (IComment (prettyStmt s))
  v <- lowerExpr e
  emit (IReturn (Just v))
lowerStmt s@(Syn.SBreak _) = do
  emit (IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((_, lEnd):_) -> emit (IGoto lEnd)
    []            -> pure ()
lowerStmt s@(Syn.SContinue _) = do
  emit (IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((lCont, _):_) -> emit (IGoto lCont)
    []             -> pure ()
lowerStmt (Syn.SAsmInline _ _) = pure ()  -- not yet supported

pushLoop :: (Label, Label) -> L ()
pushLoop pair = modify $ \s -> s { lsLoopStack = pair : lsLoopStack s }

popLoop :: L ()
popLoop = modify $ \s -> s { lsLoopStack = drop 1 (lsLoopStack s) }

-- ---------------------------------------------------------------------------
-- Source-level pretty-printing (for IComment annotations)

trunc60 :: Text -> Text
trunc60 t = if T.length t > 60 then T.take 57 t <> "..." else t

prettyTy :: Syn.Ty -> Text
prettyTy Syn.TyInt           = "int"
prettyTy Syn.TyUint          = "unsigned"
prettyTy Syn.TyVoid          = "void"
prettyTy (Syn.TyPtr t)       = prettyTy t <> "*"
prettyTy (Syn.TyArray t n)   = prettyTy t <> "[" <> T.pack (show n) <> "]"
prettyTy (Syn.TyStruct _ n)  = "struct " <> n

prettyExpr :: Syn.Expr -> Text
prettyExpr (Syn.ELit _ n)          = T.pack (show n)
prettyExpr (Syn.EVar _ v)          = v
prettyExpr (Syn.EUnary _ op e)     = prettyUnOp op <> prettyExpr e
prettyExpr (Syn.EBinary _ op l r)  = prettyExpr l <> prettyBinOp op <> prettyExpr r
prettyExpr (Syn.EAssign _ op l r)  = prettyExpr l <> prettyAssOp op <> prettyExpr r
prettyExpr (Syn.EIndex _ e i)      = prettyExpr e <> "[" <> prettyExpr i <> "]"
prettyExpr (Syn.EField _ e f)      = prettyExpr e <> "." <> f
prettyExpr (Syn.EArrow _ e f)      = prettyExpr e <> "->" <> f
prettyExpr (Syn.ECall _ f args)    = f <> "(" <> T.intercalate "," (map prettyExpr args) <> ")"
prettyExpr (Syn.ECast _ ty e)      = "(" <> prettyTy ty <> ")" <> prettyExpr e
prettyExpr (Syn.ESizeof _ _)       = "sizeof(...)"
prettyExpr (Syn.EPostfix _ op e)   = prettyExpr e <> prettyPostOp op

prettyUnOp :: Syn.UnOp -> Text
prettyUnOp Syn.UNeg    = "-"
prettyUnOp Syn.UNot    = "!"
prettyUnOp Syn.UBNot   = "~"
prettyUnOp Syn.UDeref  = "*"
prettyUnOp Syn.UAddrOf = "&"
prettyUnOp Syn.UPreInc = "++"
prettyUnOp Syn.UPreDec = "--"

prettyPostOp :: Syn.PostOp -> Text
prettyPostOp Syn.PostInc = "++"
prettyPostOp Syn.PostDec = "--"

prettyBinOp :: Syn.BinOp -> Text
prettyBinOp Syn.BAdd  = "+"
prettyBinOp Syn.BSub  = "-"
prettyBinOp Syn.BMul  = "*"
prettyBinOp Syn.BDiv  = "/"
prettyBinOp Syn.BMod  = "%"
prettyBinOp Syn.BAnd  = "&&"
prettyBinOp Syn.BOr   = "||"
prettyBinOp Syn.BBand = "&"
prettyBinOp Syn.BBor  = "|"
prettyBinOp Syn.BBxor = "^"
prettyBinOp Syn.BShl  = "<<"
prettyBinOp Syn.BShr  = ">>"
prettyBinOp Syn.BEq   = "=="
prettyBinOp Syn.BNe   = "!="
prettyBinOp Syn.BLt   = "<"
prettyBinOp Syn.BLe   = "<="
prettyBinOp Syn.BGt   = ">"
prettyBinOp Syn.BGe   = ">="

prettyAssOp :: Syn.AssOp -> Text
prettyAssOp Syn.AEq   = "="
prettyAssOp Syn.AAdd  = "+="
prettyAssOp Syn.ASub  = "-="
prettyAssOp Syn.AMul  = "*="
prettyAssOp Syn.ADiv  = "/="
prettyAssOp Syn.AMod  = "%="
prettyAssOp Syn.ABand = "&="
prettyAssOp Syn.ABor  = "|="
prettyAssOp Syn.ABxor = "^="
prettyAssOp Syn.AShl  = "<<="
prettyAssOp Syn.AShr  = ">>="

prettyStmt :: Syn.Stmt -> Text
prettyStmt (Syn.SExpr _ e)          = trunc60 (prettyExpr e)
prettyStmt (Syn.SReturn _ Nothing)   = "return"
prettyStmt (Syn.SReturn _ (Just e))  = trunc60 ("return " <> prettyExpr e)
prettyStmt (Syn.SIf _ c _ _)        = trunc60 ("if (" <> prettyExpr c <> ")")
prettyStmt (Syn.SWhile _ c _)       = trunc60 ("while (" <> prettyExpr c <> ")")
prettyStmt (Syn.SFor _ _ c _ _)     = trunc60 ("for (...; " <> maybe "" prettyExpr c <> "; ...)")
prettyStmt (Syn.SVarDecl vd)        =
  trunc60 (prettyTy (Syn.vdTy vd) <> " " <> Syn.vdName vd <>
           (case Syn.vdInit vd of { Nothing -> ""; Just _ -> " = ..." }))
prettyStmt (Syn.SBreak _)           = "break"
prettyStmt (Syn.SContinue _)        = "continue"
prettyStmt (Syn.SAsmInline _ _)     = "asm(...)"
prettyStmt (Syn.SBlock _ _)         = ""

-- ---------------------------------------------------------------------------
-- Expressions
--
-- lowerExpr  :: produces an Operand holding the value
-- lowerAddr  :: produces an Operand holding the address (lvalues only)
-- inferTy    :: re-derives the type of an expression (best-effort)

lowerExpr :: Syn.Expr -> L Operand
lowerExpr (Syn.ELit _ n)       = pure (OConst n)
lowerExpr (Syn.EVar _ name)    = do
  loc <- isLocal name
  if loc
    then pure (OTemp name)
    else do
      glb <- isGlobal name
      if glb
        then do
          gs <- gets lsGlobals
          let ty = fst (gs Map.! name)
          case ty of
            Syn.TyArray _ _ -> pure (OAddr name)        -- array decays to pointer
            Syn.TyStruct _ _ -> pure (OAddr name)       -- struct as value: address
            _ -> do
              t <- freshTemp
              emit (ILoad t (OAddr name))
              pure (OTemp t)
        else pure (OAddr name)   -- function name? unreachable in our tests
lowerExpr (Syn.EUnary _ op e)  = do
  v <- lowerExpr e
  t <- freshTemp
  case op of
    Syn.UNeg    -> emit (IUnOp t TNeg v)
    Syn.UNot    -> emit (IUnOp t TNot v)
    Syn.UBNot   -> emit (IUnOp t TBNot v)
    Syn.UDeref  -> emit (ILoad t v)
    Syn.UAddrOf -> do
      addr <- lowerAddr e
      emit (IAssign t addr)
    Syn.UPreInc -> do
      addr1 <- freshTemp
      emit (IBinOp addr1 TAdd v (OConst 1))
      assignTo e (OTemp addr1)
      emit (IAssign t (OTemp addr1))
    Syn.UPreDec -> do
      addr1 <- freshTemp
      emit (IBinOp addr1 TSub v (OConst 1))
      assignTo e (OTemp addr1)
      emit (IAssign t (OTemp addr1))
  pure (OTemp t)
lowerExpr (Syn.EBinary _ op l r) = do
  case op of
    Syn.BAnd -> lowerLogicalAnd l r   -- short-circuit
    Syn.BOr  -> lowerLogicalOr  l r
    _ -> do
      lv    <- lowerExpr l
      rv    <- lowerExpr r
      t     <- freshTemp
      tacOp <- selectBinOp op l
      emit (IBinOp t tacOp lv rv)
      pure (OTemp t)
lowerExpr (Syn.EAssign _ aop lhs rhs) = case aop of
  Syn.AEq -> do
    rv <- lowerExpr rhs
    assignTo lhs rv
    pure rv
  _ -> do
    -- compound assignment: lhs op= rhs  -->  lhs = lhs op rhs
    lv    <- lowerExpr lhs
    rv    <- lowerExpr rhs
    t     <- freshTemp
    tacOp <- selectCompoundOp aop lhs
    emit (IBinOp t tacOp lv rv)
    assignTo lhs (OTemp t)
    pure (OTemp t)
lowerExpr (Syn.EIndex _ arr idx) = do
  baseAddr <- lowerExpr arr        -- arrays decay to address; pointers are values
  iv       <- lowerExpr idx
  addr     <- freshTemp
  emit (IBinOp addr TAdd baseAddr iv)
  t <- freshTemp
  emit (ILoad t (OTemp addr))
  pure (OTemp t)
lowerExpr (Syn.EField _ inner fname) = do
  ty <- inferTy inner
  case ty of
    Syn.TyStruct _ sname -> do
      addr <- lowerAddr inner
      off  <- structOffset sname fname
      ftyp <- structFieldTy sname fname
      readField addr off ftyp
    _ -> do
      t <- freshTemp
      pure (OTemp t)
lowerExpr (Syn.EArrow _ inner fname) = do
  ty <- inferTy inner
  case ty of
    Syn.TyPtr (Syn.TyStruct _ sname) -> do
      pv   <- lowerExpr inner
      off  <- structOffset sname fname
      ftyp <- structFieldTy sname fname
      readField pv off ftyp
    _ -> do
      t <- freshTemp
      pure (OTemp t)
lowerExpr (Syn.ECall _ name args) = do
  argOps <- mapM lowerExpr args
  t <- freshTemp
  emit (ICall (Just t) name argOps)
  pure (OTemp t)
lowerExpr (Syn.ECast _ _ e)     = lowerExpr e
lowerExpr (Syn.ESizeof _ arg)   = do
  ss <- gets lsStructs
  case arg of
    Left ty -> pure (OConst (Sema.tySize ss ty))
    Right e -> do
      ty <- inferTy e
      pure (OConst (Sema.tySize ss ty))
lowerExpr (Syn.EPostfix _ pop e) = do
  ov <- lowerExpr e
  -- Save original value
  orig <- freshTemp
  emit (IAssign orig ov)
  -- Compute new value
  newv <- freshTemp
  case pop of
    Syn.PostInc -> emit (IBinOp newv TAdd ov (OConst 1))
    Syn.PostDec -> emit (IBinOp newv TSub ov (OConst 1))
  assignTo e (OTemp newv)
  pure (OTemp orig)

-- Read a value at addr+offset, of the given type.
readField :: Operand -> Int -> Syn.Ty -> L Operand
readField baseAddr off fty = do
  addr <- if off == 0
            then pure baseAddr
            else do
              a <- freshTemp
              emit (IBinOp a TAdd baseAddr (OConst off))
              pure (OTemp a)
  case fty of
    Syn.TyArray _ _   -> pure addr   -- array field: result is its address
    Syn.TyStruct _ _  -> pure addr
    _ -> do
      t <- freshTemp
      emit (ILoad t addr)
      pure (OTemp t)

-- Lower an lvalue: produce an Operand holding the address of the location.
lowerAddr :: Syn.Expr -> L Operand
lowerAddr (Syn.EVar _ name) = do
  glb <- isGlobal name
  if glb
    then pure (OAddr name)
    else pure (OLocalAddr name)
lowerAddr (Syn.EUnary _ Syn.UDeref e) = lowerExpr e
lowerAddr (Syn.EIndex _ arr idx) = do
  baseAddr <- lowerExpr arr
  iv       <- lowerExpr idx
  a <- freshTemp
  emit (IBinOp a TAdd baseAddr iv)
  pure (OTemp a)
lowerAddr (Syn.EField _ inner fname) = do
  ty <- inferTy inner
  case ty of
    Syn.TyStruct _ sname -> do
      addr <- lowerAddr inner
      off  <- structOffset sname fname
      if off == 0
        then pure addr
        else do
          a <- freshTemp
          emit (IBinOp a TAdd addr (OConst off))
          pure (OTemp a)
    _ -> pure (OConst 0)
lowerAddr (Syn.EArrow _ inner fname) = do
  ty <- inferTy inner
  case ty of
    Syn.TyPtr (Syn.TyStruct _ sname) -> do
      pv   <- lowerExpr inner
      off  <- structOffset sname fname
      if off == 0
        then pure pv
        else do
          a <- freshTemp
          emit (IBinOp a TAdd pv (OConst off))
          pure (OTemp a)
    _ -> pure (OConst 0)
lowerAddr e = lowerExpr e   -- fallback (caller error)

-- Assign rv into the location named by lhs.
assignTo :: Syn.Expr -> Operand -> L ()
assignTo (Syn.EVar _ name) rv = do
  loc <- isLocal name
  if loc
    then emit (IAssign name rv)
    else do
      glb <- isGlobal name
      when glb $ emit (IStore (OAddr name) rv)
assignTo (Syn.EUnary _ Syn.UDeref e) rv = do
  pv <- lowerExpr e
  emit (IStore pv rv)
assignTo (Syn.EIndex _ arr idx) rv = do
  baseAddr <- lowerExpr arr
  iv       <- lowerExpr idx
  a <- freshTemp
  emit (IBinOp a TAdd baseAddr iv)
  emit (IStore (OTemp a) rv)
assignTo (Syn.EField _ inner fname) rv = do
  ty <- inferTy inner
  case ty of
    Syn.TyStruct _ sname -> do
      addr <- lowerAddr inner
      off  <- structOffset sname fname
      target <- if off == 0
                  then pure addr
                  else do
                    a <- freshTemp
                    emit (IBinOp a TAdd addr (OConst off))
                    pure (OTemp a)
      emit (IStore target rv)
    _ -> pure ()
assignTo (Syn.EArrow _ inner fname) rv = do
  ty <- inferTy inner
  case ty of
    Syn.TyPtr (Syn.TyStruct _ sname) -> do
      pv   <- lowerExpr inner
      off  <- structOffset sname fname
      target <- if off == 0
                  then pure pv
                  else do
                    a <- freshTemp
                    emit (IBinOp a TAdd pv (OConst off))
                    pure (OTemp a)
      emit (IStore target rv)
    _ -> pure ()
assignTo _ _ = pure ()   -- ignored for non-lvalues

-- Re-derive the type of an expression.
inferTy :: Syn.Expr -> L Syn.Ty
inferTy (Syn.ELit _ _)        = pure Syn.TyInt
inferTy (Syn.EVar _ name)     = do
  loc <- isLocal name
  if loc
    then (Map.! name) <$> gets lsLocals
    else do
      glb <- isGlobal name
      if glb
        then (fst . (Map.! name)) <$> gets lsGlobals
        else pure Syn.TyInt
inferTy (Syn.EUnary _ op e)   = do
  t <- inferTy e
  case op of
    Syn.UDeref  -> case t of
      Syn.TyPtr inner -> pure inner
      _               -> pure Syn.TyInt
    Syn.UAddrOf -> pure (Syn.TyPtr t)
    _           -> pure t
inferTy (Syn.EBinary _ op l _) = case op of
  Syn.BAdd  -> inferTy l
  Syn.BSub  -> inferTy l
  Syn.BMul  -> inferTy l
  Syn.BBand -> inferTy l
  Syn.BBor  -> inferTy l
  Syn.BBxor -> inferTy l
  _         -> pure Syn.TyInt
inferTy (Syn.EAssign _ _ l _) = inferTy l
inferTy (Syn.EIndex _ arr _) = do
  t <- inferTy arr
  case t of
    Syn.TyPtr inner   -> pure inner
    Syn.TyArray inner _ -> pure inner
    _                 -> pure Syn.TyInt
inferTy (Syn.EField _ inner fname) = do
  t <- inferTy inner
  case t of
    Syn.TyStruct _ sname -> structFieldTy sname fname
    _                    -> pure Syn.TyInt
inferTy (Syn.EArrow _ inner fname) = do
  t <- inferTy inner
  case t of
    Syn.TyPtr (Syn.TyStruct _ sname) -> structFieldTy sname fname
    _                                -> pure Syn.TyInt
inferTy (Syn.ECall _ name _) = do
  fs <- gets lsFuncs
  case Map.lookup name fs of
    Just (rt, _) -> pure rt
    Nothing      -> pure Syn.TyInt
inferTy (Syn.ECast _ ty _)   = pure ty
inferTy (Syn.ESizeof _ _)    = pure Syn.TyInt
inferTy (Syn.EPostfix _ _ e) = inferTy e

-- ---------------------------------------------------------------------------
-- Helpers

-- Choose signed vs unsigned TAC op based on the type of the left operand.
selectBinOp :: Syn.BinOp -> Syn.Expr -> L BinOp
selectBinOp op lExpr = do
  lTy <- inferTy lExpr
  let u = lTy == Syn.TyUint
  pure $ case op of
    Syn.BLt  | u -> TULt
    Syn.BLe  | u -> TULe
    Syn.BGt  | u -> TUGt
    Syn.BGe  | u -> TUGe
    Syn.BShr | u -> TUShr
    _            -> mapBinOp op

selectCompoundOp :: Syn.AssOp -> Syn.Expr -> L BinOp
selectCompoundOp Syn.AShr lhs = do
  ty <- inferTy lhs
  pure $ if ty == Syn.TyUint then TUShr else TShr
selectCompoundOp aop _ = pure (compoundOp aop)

mapBinOp :: Syn.BinOp -> BinOp
mapBinOp Syn.BAdd  = TAdd
mapBinOp Syn.BSub  = TSub
mapBinOp Syn.BMul  = TMul
mapBinOp Syn.BDiv  = TDiv
mapBinOp Syn.BMod  = TMod
mapBinOp Syn.BAnd  = TAnd
mapBinOp Syn.BOr   = TOr
mapBinOp Syn.BBand = TBand
mapBinOp Syn.BBor  = TBor
mapBinOp Syn.BBxor = TBxor
mapBinOp Syn.BShl  = TShl
mapBinOp Syn.BShr  = TShr
mapBinOp Syn.BEq   = TEq
mapBinOp Syn.BNe   = TNe
mapBinOp Syn.BLt   = TLt
mapBinOp Syn.BLe   = TLe
mapBinOp Syn.BGt   = TGt
mapBinOp Syn.BGe   = TGe

compoundOp :: Syn.AssOp -> BinOp
compoundOp Syn.AAdd  = TAdd
compoundOp Syn.ASub  = TSub
compoundOp Syn.AMul  = TMul
compoundOp Syn.ADiv  = TDiv
compoundOp Syn.AMod  = TMod
compoundOp Syn.ABand = TBand
compoundOp Syn.ABor  = TBor
compoundOp Syn.ABxor = TBxor
compoundOp Syn.AShl  = TShl
compoundOp Syn.AShr  = TShr
compoundOp Syn.AEq   = TAdd  -- unreachable; AEq handled separately

-- Short-circuit && and || lowered with branches.
lowerLogicalAnd :: Syn.Expr -> Syn.Expr -> L Operand
lowerLogicalAnd l r = do
  t <- freshTemp
  lFalse <- freshLabel "and_false"
  lEnd   <- freshLabel "and_end"
  lv <- lowerExpr l
  emit (IIfZ lv lFalse)
  rv <- lowerExpr r
  emit (IIfZ rv lFalse)
  emit (IAssign t (OConst 1))
  emit (IGoto lEnd)
  emit (ILabel lFalse)
  emit (IAssign t (OConst 0))
  emit (ILabel lEnd)
  pure (OTemp t)

lowerLogicalOr :: Syn.Expr -> Syn.Expr -> L Operand
lowerLogicalOr l r = do
  t <- freshTemp
  lTrue <- freshLabel "or_true"
  lEnd  <- freshLabel "or_end"
  lv <- lowerExpr l
  emit (IIfNZ lv lTrue)
  rv <- lowerExpr r
  emit (IIfNZ rv lTrue)
  emit (IAssign t (OConst 0))
  emit (IGoto lEnd)
  emit (ILabel lTrue)
  emit (IAssign t (OConst 1))
  emit (ILabel lEnd)
  pure (OTemp t)
