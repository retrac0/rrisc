module RCC.Lower
  ( lower
  ) where

import Control.Monad (when, unless, forM_)
import Control.Monad.State
import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T

import qualified RCC.Sema   as Sema
import qualified RCC.Syntax as Syn
import qualified RCC.TAC    as TAC

-- ---------------------------------------------------------------------------
-- Float48 encoding

doubleToF48 :: Double -> [Int]
doubleToF48 x
  | isNaN x      = [0x7FF, 0, 0x400, 0]
  | isInfinite x = if x > 0 then [0x7FF, 0, 0, 0] else [0xFFF, 0, 0, 0]
  | x == 0.0     = [0, 0, 0, 0]
  | otherwise    =
      let sign      = if x < 0 then 1 else 0
          (m, n)    = decodeFloat (abs x)
          -- m in [2^52, 2^53) for normal doubles; x = m * 2^n
          -- float48: sig48 = top 36 bits of m; exp48 = n + 1076
          sig48     = fromInteger m `shiftR` 17 :: Int
          exp48     = n + 1076
          w0        = (sign `shiftL` 11) .|. (exp48 .&. 0x7FF)
          w1        = (sig48 `shiftR` 24) .&. 0xFFF
          w2        = (sig48 `shiftR` 12) .&. 0xFFF
          w3        = sig48 .&. 0xFFF
      in if exp48 >= 0x7FF
           then [(sign `shiftL` 11) .|. 0x7FF, 0, 0, 0]
           else if exp48 <= 0
                  then [0, 0, 0, 0]
                  else [w0, w1, w2, w3]

-- ---------------------------------------------------------------------------
-- Lowering monad

data LS = LS
  { lsTemp        :: Int
  , lsLabel       :: Int
  , lsInstrs      :: [TAC.Instr]                        -- reversed
  , lsLocals      :: Map Text Syn.Ty                    -- current func locals + params
  , lsGlobals     :: Map Text (Syn.Ty, Bool)
  , lsStructs     :: Map Text [Syn.Field]
  , lsFuncs       :: Map Text (Syn.Ty, [(Syn.Ty, Text)])
  , lsLoopStack   :: [(TAC.Label, TAC.Label)]           -- (continue, break)
  , lsProcs       :: [TAC.Proc]                         -- reversed
  , lsGlobalDefs  :: [TAC.Global]                       -- reversed
  , lsConstLocals :: Map Text TAC.Operand               -- const local aggregates -> rodata addr
  }

emptyLS :: LS
emptyLS = LS 0 0 [] Map.empty Map.empty Map.empty Map.empty [] [] [] Map.empty

type L = State LS

emit :: TAC.Instr -> L ()
emit i = modify $ \s -> s { lsInstrs = i : lsInstrs s }

freshTemp :: L TAC.Temp
freshTemp = do
  n <- gets lsTemp
  modify $ \s -> s { lsTemp = n + 1 }
  pure $ "%t" <> T.pack (show n)

freshLabel :: Text -> L TAC.Label
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

addConstLocal :: Text -> TAC.Operand -> L ()
addConstLocal name op =
  modify $ \s -> s { lsConstLocals = Map.insert name op (lsConstLocals s) }

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

lower :: Sema.CheckedProg -> TAC.TACProg
lower (Syn.Prog decls) =
  let final = execState (lowerProg decls) emptyLS
  in TAC.TACProg (reverse (lsGlobalDefs final)) (reverse (lsProcs final))

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
  let name  = Syn.vdName vd
      ty    = Syn.vdTy vd
      sz    = Sema.tySize ss ty
      isC   = Syn.vdConst vd
      initVals = case ty of
        Syn.TyFloat -> case Syn.vdInit vd of
          Just (Syn.IExpr (Syn.EFloatLit _ d)) -> doubleToF48 d
          _                                    -> replicate 4 0
        _ -> case Syn.vdInit vd of
          Just (Syn.IExpr e)  -> [evalConst e]
          Just (Syn.IList es) -> map evalConst es
          Nothing             -> []
  modify $ \s -> s { lsGlobals    = Map.insert name (ty, isC) (lsGlobals s)
                   , lsGlobalDefs = TAC.Global name sz initVals isC : lsGlobalDefs s }
  where
    evalConst (Syn.ELit _ n) = n
    evalConst _              = 0
collectTop _ = pure ()

lowerTop :: Syn.TopDecl -> L ()
lowerTop (Syn.TDFunc fd) = case Syn.fdBody fd of
  Nothing   -> pure ()
  Just body -> do
    s0 <- get
    put s0 { lsTemp = 0, lsInstrs = [], lsLocals = Map.empty
           , lsLoopStack = [], lsConstLocals = Map.empty }
    mapM_ (\(ty, n) -> addLocal n ty) (Syn.fdParams fd)
    mapM_ lowerStmt body
    -- Implicit return at end of body (0 if int, void otherwise).
    sf <- get
    let alreadyReturned = case lsInstrs sf of
          (TAC.IReturn _ : _) -> True
          _                   -> False
    unless alreadyReturned $ do
      if Syn.fdRetTy fd == Syn.TyVoid
        then emit (TAC.IReturn Nothing)
        else emit (TAC.IReturn (Just (TAC.OConst 0)))
    sg <- get
    let ss        = lsStructs sg
        paramSet  = Map.fromList (map (\(ty, n) -> (n, ty)) (Syn.fdParams fd))
        locSzs    = Map.fromList
          [ (name, sz)
          | (name, ty) <- Map.toList (lsLocals sg)
          , Map.notMember name paramSet
          , Map.notMember name (lsConstLocals sg)
          , let sz = Sema.tySize ss ty
          , sz > 1
          ]
        proc = TAC.Proc (Syn.fdName fd) (map snd (Syn.fdParams fd))
                        (reverse (lsInstrs sg)) locSzs
    put sg { lsTemp        = lsTemp s0
           , lsInstrs      = lsInstrs s0
           , lsLocals      = lsLocals s0
           , lsLoopStack   = lsLoopStack s0
           , lsConstLocals = lsConstLocals s0
           , lsProcs       = proc : lsProcs sg
           }
lowerTop _ = pure ()

-- ---------------------------------------------------------------------------
-- Statements

lowerStmt :: Syn.Stmt -> L ()
lowerStmt (Syn.SBlock _ ss)   = mapM_ lowerStmt ss
lowerStmt s@(Syn.SVarDecl vd) = do
  emit (TAC.IComment (prettyStmt s))
  let name = Syn.vdName vd
      ty   = Syn.vdTy vd
  addLocal name ty
  case Syn.vdInit vd of
    Nothing ->
      case ty of
        Syn.TyArray  _ _ -> emit (TAC.IAllocLocal name)
        Syn.TyStruct _ _ -> emit (TAC.IAllocLocal name)
        Syn.TyFloat      -> emit (TAC.IAllocLocal name)
        _                -> pure ()
    Just (Syn.IList es) ->
      if Syn.vdConst vd && all isLitExpr es
        then do  -- const aggregate with all-literal init -> rodata global
          ss <- gets lsStructs
          let sz       = Sema.tySize ss ty
              initVals = [n | Syn.ELit _ n <- es]
          synName <- freshLabel ("const_" <> name)
          modify $ \ls -> ls { lsGlobalDefs = TAC.Global synName sz initVals True
                                              : lsGlobalDefs ls }
          addConstLocal name (TAC.OAddr synName)
        else initAggrOnStack name ty es
    Just (Syn.IExpr e) ->
      case ty of
        Syn.TyArray  _ _ -> emit (TAC.IAllocLocal name)
        Syn.TyStruct _ _ -> emit (TAC.IAllocLocal name)
        Syn.TyFloat -> do
          emit (TAC.IAllocLocal name)
          src <- lowerExpr e
          emit (TAC.ICall Nothing "__fcopy" [TAC.OLocalAddr name, src])
        _ -> do
          v <- lowerExpr e
          emit (TAC.IAssign name v)
lowerStmt s@(Syn.SExpr _ e)   = do
  emit (TAC.IComment (prettyStmt s))
  () <$ lowerExpr e
lowerStmt s@(Syn.SIf _ c t me) = do
  emit (TAC.IComment (prettyStmt s))
  cv <- lowerExpr c
  case me of
    Nothing -> do
      lEnd <- freshLabel "endif"
      emit (TAC.IIfZ cv lEnd)
      lowerStmt t
      emit (TAC.ILabel lEnd)
    Just el -> do
      lElse <- freshLabel "else"
      lEnd  <- freshLabel "endif"
      emit (TAC.IIfZ cv lElse)
      lowerStmt t
      emit (TAC.IGoto lEnd)
      emit (TAC.ILabel lElse)
      lowerStmt el
      emit (TAC.ILabel lEnd)
lowerStmt s@(Syn.SWhile _ c body) = do
  emit (TAC.IComment (prettyStmt s))
  lHead <- freshLabel "while"
  lEnd  <- freshLabel "endwhile"
  emit (TAC.ILabel lHead)
  cv <- lowerExpr c
  emit (TAC.IIfZ cv lEnd)
  pushLoop (lHead, lEnd)
  lowerStmt body
  popLoop
  emit (TAC.IGoto lHead)
  emit (TAC.ILabel lEnd)
lowerStmt s@(Syn.SFor _ ini c step body) = do
  emit (TAC.IComment (prettyStmt s))
  case ini of
    Syn.FIDecl vd -> lowerStmt (Syn.SVarDecl vd)
    Syn.FIExpr Nothing -> pure ()
    Syn.FIExpr (Just e) -> () <$ lowerExpr e
  lHead <- freshLabel "for"
  lCont <- freshLabel "forcont"
  lEnd  <- freshLabel "endfor"
  emit (TAC.ILabel lHead)
  case c of
    Nothing -> pure ()
    Just ce -> do
      cv <- lowerExpr ce
      emit (TAC.IIfZ cv lEnd)
  pushLoop (lCont, lEnd)
  lowerStmt body
  popLoop
  emit (TAC.ILabel lCont)
  case step of
    Nothing -> pure ()
    Just se -> () <$ lowerExpr se
  emit (TAC.IGoto lHead)
  emit (TAC.ILabel lEnd)
lowerStmt s@(Syn.SReturn _ Nothing) = do
  emit (TAC.IComment (prettyStmt s))
  emit (TAC.IReturn Nothing)
lowerStmt s@(Syn.SReturn _ (Just e)) = do
  emit (TAC.IComment (prettyStmt s))
  v <- lowerExpr e
  emit (TAC.IReturn (Just v))
lowerStmt s@(Syn.SBreak _) = do
  emit (TAC.IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((_, lEnd):_) -> emit (TAC.IGoto lEnd)
    []            -> pure ()
lowerStmt s@(Syn.SContinue _) = do
  emit (TAC.IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((lCont, _):_) -> emit (TAC.IGoto lCont)
    []             -> pure ()
lowerStmt (Syn.SAsmInline _ txt) = emit (TAC.IAsmInline txt)

pushLoop :: (TAC.Label, TAC.Label) -> L ()
pushLoop pair = modify $ \s -> s { lsLoopStack = pair : lsLoopStack s }

popLoop :: L ()
popLoop = modify $ \s -> s { lsLoopStack = drop 1 (lsLoopStack s) }

isLitExpr :: Syn.Expr -> Bool
isLitExpr (Syn.ELit _ _) = True
isLitExpr _              = False

-- Emit IAllocLocal + runtime stores for a non-rodata aggregate initializer.
initAggrOnStack :: Text -> Syn.Ty -> [Syn.Expr] -> L ()
initAggrOnStack name ty es = do
  emit (TAC.IAllocLocal name)
  ss <- gets lsStructs
  let elemSz = case ty of
        Syn.TyArray inner _ -> Sema.tySize ss inner
        _                   -> 1
  forM_ (zip [0..] es) $ \(i, e) -> do
    ev <- lowerExpr e
    let off = i * elemSz
    addrOp <- if off == 0
                then pure (TAC.OLocalAddr name)
                else do
                  at <- freshTemp
                  emit (TAC.IBinOp at TAC.TAdd (TAC.OLocalAddr name) (TAC.OConst off))
                  pure (TAC.OTemp at)
    emit (TAC.IStore addrOp ev)

-- ---------------------------------------------------------------------------
-- Source-level pretty-printing (for IComment annotations)

trunc60 :: Text -> Text
trunc60 t = if T.length t > 60 then T.take 57 t <> "..." else t

prettyTy :: Syn.Ty -> Text
prettyTy Syn.TyInt           = "int"
prettyTy Syn.TyUint          = "unsigned"
prettyTy Syn.TyVoid          = "void"
prettyTy Syn.TyFloat         = "float"
prettyTy (Syn.TyPtr t)       = prettyTy t <> "*"
prettyTy (Syn.TyArray t n)   = prettyTy t <> "[" <> T.pack (show n) <> "]"
prettyTy (Syn.TyStruct _ n)  = "struct " <> n

prettyExpr :: Syn.Expr -> Text
prettyExpr (Syn.ELit _ n)               = T.pack (show n)
prettyExpr (Syn.EFloatLit _ d)          = T.pack (show d)
prettyExpr (Syn.EString _ s)            = "\"" <> s <> "\""
prettyExpr (Syn.EVar _ v)               = v
prettyExpr (Syn.EUnary _ op e)          = prettyUnOp op <> prettyExpr e
prettyExpr (Syn.EBinary _ op l r)       = prettyExpr l <> prettyBinOp op <> prettyExpr r
prettyExpr (Syn.EAssign _ op l r)       = prettyExpr l <> prettyAssOp op <> prettyExpr r
prettyExpr (Syn.EIndex _ e i)           = prettyExpr e <> "[" <> prettyExpr i <> "]"
prettyExpr (Syn.EField _ e f)           = prettyExpr e <> "." <> f
prettyExpr (Syn.EArrow _ e f)           = prettyExpr e <> "->" <> f
prettyExpr (Syn.ECall _ f args)         = f <> "(" <> T.intercalate "," (map prettyExpr args) <> ")"
prettyExpr (Syn.ECast _ ty e)           = "(" <> prettyTy ty <> ")" <> prettyExpr e
prettyExpr (Syn.ESizeof _ _)            = "sizeof(...)"
prettyExpr (Syn.EPostfix _ op e)        = prettyExpr e <> prettyPostOp op
prettyExpr (Syn.ETernary _ c t f)       = prettyExpr c <> "?" <> prettyExpr t <> ":" <> prettyExpr f
prettyExpr (Syn.ECompoundLit _ ty _)    = "(" <> prettyTy ty <> "){...}"

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

lowerExpr :: Syn.Expr -> L TAC.Operand
lowerExpr (Syn.ELit _ n)       = pure (TAC.OConst n)
lowerExpr (Syn.EFloatLit _ d)  = do
  name <- freshLabel "flit"
  modify $ \ls -> ls { lsGlobalDefs = TAC.Global name 4 (doubleToF48 d) True
                                      : lsGlobalDefs ls }
  pure (TAC.OAddr name)
lowerExpr (Syn.EString _ txt)  = do
  name <- freshLabel "str"
  let chars = map fromEnum (T.unpack txt) ++ [0]
      sz    = length chars
  modify $ \ls -> ls { lsGlobalDefs = TAC.Global name sz chars True : lsGlobalDefs ls }
  pure (TAC.OAddr name)
lowerExpr (Syn.EVar _ name)    = do
  cl <- gets lsConstLocals
  case Map.lookup name cl of
    Just op -> pure op   -- const local aggregate (rodata): return its address operand
    Nothing -> do
      loc <- isLocal name
      if loc
        then do
          ls <- gets lsLocals
          case Map.lookup name ls of
            Just (Syn.TyArray  _ _) -> pure (TAC.OLocalAddr name)
            Just (Syn.TyStruct _ _) -> pure (TAC.OLocalAddr name)
            Just Syn.TyFloat        -> pure (TAC.OLocalAddr name)
            _                       -> pure (TAC.OTemp name)
        else do
          glb <- isGlobal name
          if glb
            then do
              gs <- gets lsGlobals
              let ty = fst (gs Map.! name)
              case ty of
                Syn.TyArray  _ _ -> pure (TAC.OAddr name)
                Syn.TyStruct _ _ -> pure (TAC.OAddr name)
                Syn.TyFloat      -> pure (TAC.OAddr name)
                _ -> do
                  t <- freshTemp
                  emit (TAC.ILoad t (TAC.OAddr name))
                  pure (TAC.OTemp t)
            else pure (TAC.OAddr name)   -- function name
lowerExpr (Syn.EUnary _ op e)  = do
  et <- inferTy e
  v  <- lowerExpr e
  -- Float pointer dereference: v already holds the float's base address.
  -- No load needed; pass v directly as the float operand.
  case (op, et) of
    (Syn.UDeref, Syn.TyPtr Syn.TyFloat) -> pure v
    _ -> do
      t  <- freshTemp
      if op == Syn.UNeg && et == Syn.TyFloat
        then do
          addLocal t Syn.TyFloat
          emit (TAC.IAllocLocal t)
          emit (TAC.ICall Nothing "__fneg" [TAC.OLocalAddr t, v])
          pure (TAC.OLocalAddr t)
        else do
          case op of
            Syn.UNeg    -> emit (TAC.IUnOp t TAC.TNeg v)
            Syn.UNot    -> emit (TAC.IUnOp t TAC.TNot v)
            Syn.UBNot   -> emit (TAC.IUnOp t TAC.TBNot v)
            Syn.UDeref  -> emit (TAC.ILoad t v)
            Syn.UAddrOf -> do
              addr <- lowerAddr e
              emit (TAC.IAssign t addr)
            Syn.UPreInc -> do
              addr1 <- freshTemp
              emit (TAC.IBinOp addr1 TAC.TAdd v (TAC.OConst 1))
              assignTo e (TAC.OTemp addr1)
              emit (TAC.IAssign t (TAC.OTemp addr1))
            Syn.UPreDec -> do
              addr1 <- freshTemp
              emit (TAC.IBinOp addr1 TAC.TSub v (TAC.OConst 1))
              assignTo e (TAC.OTemp addr1)
              emit (TAC.IAssign t (TAC.OTemp addr1))
          pure (TAC.OTemp t)
lowerExpr (Syn.EBinary _ op l r) = do
  lt <- inferTy l
  case op of
    Syn.BAnd -> lowerLogicalAnd l r   -- short-circuit
    Syn.BOr  -> lowerLogicalOr  l r
    _ | lt == Syn.TyFloat -> lowerFloatBinOp op l r
    _ -> do
      lv    <- lowerExpr l
      rv    <- lowerExpr r
      t     <- freshTemp
      tacOp <- selectBinOp op l
      emit (TAC.IBinOp t tacOp lv rv)
      pure (TAC.OTemp t)
lowerExpr (Syn.EAssign _ aop lhs rhs) = do
  lt <- inferTy lhs
  case aop of
    Syn.AEq | lt == Syn.TyFloat -> do
      dst <- lowerAddr lhs
      src <- lowerExpr rhs
      emit (TAC.ICall Nothing "__fcopy" [dst, src])
      pure src
    Syn.AEq -> do
      rv <- lowerExpr rhs
      assignTo lhs rv
      pure rv
    _ | lt == Syn.TyFloat -> do
      -- float compound assignment: lower as binary op then assign
      let synOp = compoundToSynBinOp aop
      result <- lowerExpr (Syn.EBinary (Syn.exprSpan lhs) synOp lhs rhs)
      dst    <- lowerAddr lhs
      emit (TAC.ICall Nothing "__fcopy" [dst, result])
      pure result
    _ -> do
      -- integer compound assignment: lhs op= rhs  -->  lhs = lhs op rhs
      lv    <- lowerExpr lhs
      rv    <- lowerExpr rhs
      t     <- freshTemp
      tacOp <- selectCompoundOp aop lhs
      emit (TAC.IBinOp t tacOp lv rv)
      assignTo lhs (TAC.OTemp t)
      pure (TAC.OTemp t)
lowerExpr (Syn.EIndex _ arr idx) = do
  arrTy <- inferTy arr
  let elemTy = case arrTy of
        Syn.TyPtr   inner   -> inner
        Syn.TyArray inner _ -> inner
        _                   -> Syn.TyInt
  addr <- indexAddr arr idx
  case elemTy of
    Syn.TyFloat      -> pure addr
    Syn.TyArray  _ _ -> pure addr
    Syn.TyStruct _ _ -> pure addr
    _ -> do
      t <- freshTemp
      emit (TAC.ILoad t addr)
      pure (TAC.OTemp t)
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
      pure (TAC.OTemp t)
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
      pure (TAC.OTemp t)
lowerExpr (Syn.ECall _ name args) = do
  argOps <- mapM lowerExpr args
  t <- freshTemp
  emit (TAC.ICall (Just t) name argOps)
  pure (TAC.OTemp t)
lowerExpr (Syn.ETernary _ cond t f) = do
  cv     <- lowerExpr cond
  result <- freshTemp
  lElse  <- freshLabel "tern_else"
  lEnd   <- freshLabel "tern_end"
  emit (TAC.IIfZ cv lElse)
  tv <- lowerExpr t
  emit (TAC.IAssign result tv)
  emit (TAC.IGoto lEnd)
  emit (TAC.ILabel lElse)
  fv <- lowerExpr f
  emit (TAC.IAssign result fv)
  emit (TAC.ILabel lEnd)
  pure (TAC.OTemp result)
lowerExpr (Syn.ECompoundLit _ ty es) = do
  name <- freshTemp
  addLocal name ty
  case ty of
    Syn.TyArray  _ _ -> initAggrOnStack name ty es
    Syn.TyStruct _ _ -> initAggrOnStack name ty es
    _ -> case es of
           [e] -> do { v <- lowerExpr e; emit (TAC.IAssign name v) }
           _   -> pure ()
  pure (TAC.OLocalAddr name)
lowerExpr (Syn.ECast _ toTy e)  = do
  fromTy <- inferTy e
  case (fromTy, toTy) of
    (Syn.TyFloat, Syn.TyInt) -> do
      src <- lowerExpr e
      t   <- freshTemp
      emit (TAC.ICall (Just t) "__ftoi" [src])
      pure (TAC.OTemp t)
    (Syn.TyFloat, Syn.TyUint) -> do
      src <- lowerExpr e
      t   <- freshTemp
      emit (TAC.ICall (Just t) "__ftoi" [src])
      pure (TAC.OTemp t)
    (_, Syn.TyFloat) | fromTy /= Syn.TyFloat -> do
      iv  <- lowerExpr e
      t   <- freshTemp
      addLocal t Syn.TyFloat
      emit (TAC.IAllocLocal t)
      emit (TAC.ICall Nothing "__itof" [TAC.OLocalAddr t, iv])
      pure (TAC.OLocalAddr t)
    _ -> lowerExpr e
lowerExpr (Syn.ESizeof _ arg)   = do
  ss <- gets lsStructs
  case arg of
    Left ty -> pure (TAC.OConst (Sema.tySize ss ty))
    Right e -> do
      ty <- inferTy e
      pure (TAC.OConst (Sema.tySize ss ty))
lowerExpr (Syn.EPostfix _ pop e) = do
  ov <- lowerExpr e
  -- Save original value
  orig <- freshTemp
  emit (TAC.IAssign orig ov)
  -- Compute new value
  newv <- freshTemp
  case pop of
    Syn.PostInc -> emit (TAC.IBinOp newv TAC.TAdd ov (TAC.OConst 1))
    Syn.PostDec -> emit (TAC.IBinOp newv TAC.TSub ov (TAC.OConst 1))
  assignTo e (TAC.OTemp newv)
  pure (TAC.OTemp orig)

-- Read a value at addr+offset, of the given type.
readField :: TAC.Operand -> Int -> Syn.Ty -> L TAC.Operand
readField baseAddr off fty = do
  addr <- if off == 0
            then pure baseAddr
            else do
              a <- freshTemp
              emit (TAC.IBinOp a TAC.TAdd baseAddr (TAC.OConst off))
              pure (TAC.OTemp a)
  case fty of
    Syn.TyArray _ _   -> pure addr
    Syn.TyStruct _ _  -> pure addr
    Syn.TyFloat       -> pure addr   -- float field: result is its address
    _ -> do
      t <- freshTemp
      emit (TAC.ILoad t addr)
      pure (TAC.OTemp t)

-- Compute address of arr[idx], scaling by element size.
indexAddr :: Syn.Expr -> Syn.Expr -> L TAC.Operand
indexAddr arr idx = do
  arrTy <- inferTy arr
  ss    <- gets lsStructs
  let elemSz = case arrTy of
        Syn.TyPtr   inner   -> Sema.tySize ss inner
        Syn.TyArray inner _ -> Sema.tySize ss inner
        _                   -> 1
  baseAddr <- lowerExpr arr
  iv       <- lowerExpr idx
  scaledIv <- if elemSz <= 1
                then pure iv
                else do
                  si <- freshTemp
                  emit (TAC.IBinOp si TAC.TMul iv (TAC.OConst elemSz))
                  pure (TAC.OTemp si)
  a <- freshTemp
  emit (TAC.IBinOp a TAC.TAdd baseAddr scaledIv)
  pure (TAC.OTemp a)

-- Lower an lvalue: produce an Operand holding the address of the location.
lowerAddr :: Syn.Expr -> L TAC.Operand
lowerAddr (Syn.EVar _ name) = do
  cl <- gets lsConstLocals
  case Map.lookup name cl of
    Just op -> pure op
    Nothing -> do
      glb <- isGlobal name
      if glb
        then pure (TAC.OAddr name)
        else pure (TAC.OLocalAddr name)
lowerAddr (Syn.EUnary _ Syn.UDeref e) = lowerExpr e
lowerAddr (Syn.EIndex _ arr idx) = indexAddr arr idx
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
          emit (TAC.IBinOp a TAC.TAdd addr (TAC.OConst off))
          pure (TAC.OTemp a)
    _ -> pure (TAC.OConst 0)
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
          emit (TAC.IBinOp a TAC.TAdd pv (TAC.OConst off))
          pure (TAC.OTemp a)
    _ -> pure (TAC.OConst 0)
lowerAddr e = lowerExpr e   -- fallback (caller error)

-- Assign rv into the location named by lhs.
assignTo :: Syn.Expr -> TAC.Operand -> L ()
assignTo (Syn.EVar _ name) rv = do
  loc <- isLocal name
  if loc
    then do
      ls <- gets lsLocals
      case Map.lookup name ls of
        Just Syn.TyFloat -> emit (TAC.ICall Nothing "__fcopy" [TAC.OLocalAddr name, rv])
        _                -> emit (TAC.IAssign name rv)
    else do
      glb <- isGlobal name
      when glb $ do
        gs <- gets lsGlobals
        case Map.lookup name gs of
          Just (Syn.TyFloat, _) -> emit (TAC.ICall Nothing "__fcopy" [TAC.OAddr name, rv])
          _                     -> emit (TAC.IStore (TAC.OAddr name) rv)
assignTo (Syn.EUnary _ Syn.UDeref e) rv = do
  pv <- lowerExpr e
  emit (TAC.IStore pv rv)
assignTo (Syn.EIndex _ arr idx) rv = do
  arrTy <- inferTy arr
  let elemTy = case arrTy of
        Syn.TyPtr   inner   -> inner
        Syn.TyArray inner _ -> inner
        _                   -> Syn.TyInt
  addr <- indexAddr arr idx
  case elemTy of
    Syn.TyFloat -> emit (TAC.ICall Nothing "__fcopy" [addr, rv])
    _           -> emit (TAC.IStore addr rv)
assignTo (Syn.EField _ inner fname) rv = do
  ty <- inferTy inner
  case ty of
    Syn.TyStruct _ sname -> do
      addr  <- lowerAddr inner
      off   <- structOffset sname fname
      ftyp  <- structFieldTy sname fname
      target <- if off == 0
                  then pure addr
                  else do
                    a <- freshTemp
                    emit (TAC.IBinOp a TAC.TAdd addr (TAC.OConst off))
                    pure (TAC.OTemp a)
      case ftyp of
        Syn.TyFloat -> emit (TAC.ICall Nothing "__fcopy" [target, rv])
        _           -> emit (TAC.IStore target rv)
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
                    emit (TAC.IBinOp a TAC.TAdd pv (TAC.OConst off))
                    pure (TAC.OTemp a)
      emit (TAC.IStore target rv)
    _ -> pure ()
assignTo _ _ = pure ()   -- ignored for non-lvalues

-- Re-derive the type of an expression.
inferTy :: Syn.Expr -> L Syn.Ty
inferTy (Syn.ELit _ _)        = pure Syn.TyInt
inferTy (Syn.EFloatLit _ _)   = pure Syn.TyFloat
inferTy (Syn.EString _ _)     = pure (Syn.TyPtr Syn.TyInt)
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
  Syn.BDiv  -> inferTy l
  Syn.BMod  -> inferTy l
  Syn.BBand -> inferTy l
  Syn.BBor  -> inferTy l
  Syn.BBxor -> inferTy l
  _         -> pure Syn.TyInt
inferTy (Syn.EAssign _ _ l _) = inferTy l
inferTy (Syn.EIndex _ arr _) = do
  t <- inferTy arr
  case t of
    Syn.TyPtr inner     -> pure inner
    Syn.TyArray inner _ -> pure inner
    _                   -> pure Syn.TyInt
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
inferTy (Syn.ECast _ ty _)        = pure ty
inferTy (Syn.ESizeof _ _)         = pure Syn.TyInt
inferTy (Syn.EPostfix _ _ e)      = inferTy e
inferTy (Syn.ETernary _ _ t _)    = inferTy t
inferTy (Syn.ECompoundLit _ ty _) = pure ty

-- ---------------------------------------------------------------------------
-- Float binary operations

lowerFloatBinOp :: Syn.BinOp -> Syn.Expr -> Syn.Expr -> L TAC.Operand
lowerFloatBinOp op l r = do
  la <- lowerExpr l
  ra <- lowerExpr r
  case op of
    Syn.BAdd -> floatArith "__fadd" la ra
    Syn.BSub -> floatArith "__fsub" la ra
    Syn.BMul -> floatArith "__fmul" la ra
    Syn.BDiv -> floatArith "__fdiv" la ra
    _        -> floatCmp op la ra

floatArith :: Text -> TAC.Operand -> TAC.Operand -> L TAC.Operand
floatArith fn la ra = do
  res <- freshTemp
  addLocal res Syn.TyFloat
  emit (TAC.IAllocLocal res)
  emit (TAC.ICall Nothing fn [TAC.OLocalAddr res, la, ra])
  pure (TAC.OLocalAddr res)

floatCmp :: Syn.BinOp -> TAC.Operand -> TAC.Operand -> L TAC.Operand
floatCmp op la ra = do
  cmpT <- freshTemp
  emit (TAC.ICall (Just cmpT) "__fcmp" [la, ra])
  t <- freshTemp
  let tacOp = case op of
        Syn.BEq -> TAC.TEq
        Syn.BNe -> TAC.TNe
        Syn.BLt -> TAC.TLt
        Syn.BLe -> TAC.TLe
        Syn.BGt -> TAC.TGt
        Syn.BGe -> TAC.TGe
        _       -> TAC.TEq
  emit (TAC.IBinOp t tacOp (TAC.OTemp cmpT) (TAC.OConst 0))
  pure (TAC.OTemp t)

compoundToSynBinOp :: Syn.AssOp -> Syn.BinOp
compoundToSynBinOp Syn.AAdd  = Syn.BAdd
compoundToSynBinOp Syn.ASub  = Syn.BSub
compoundToSynBinOp Syn.AMul  = Syn.BMul
compoundToSynBinOp Syn.ADiv  = Syn.BDiv
compoundToSynBinOp _         = Syn.BAdd  -- fallback; caller ensures float-valid ops

-- ---------------------------------------------------------------------------
-- Helpers

-- Choose signed vs unsigned TAC op based on the type of the left operand.
selectBinOp :: Syn.BinOp -> Syn.Expr -> L TAC.BinOp
selectBinOp op lExpr = do
  lTy <- inferTy lExpr
  let u = lTy == Syn.TyUint
  pure $ case op of
    Syn.BLt  | u -> TAC.TULt
    Syn.BLe  | u -> TAC.TULe
    Syn.BGt  | u -> TAC.TUGt
    Syn.BGe  | u -> TAC.TUGe
    Syn.BShr | u -> TAC.TUShr
    _            -> mapBinOp op

selectCompoundOp :: Syn.AssOp -> Syn.Expr -> L TAC.BinOp
selectCompoundOp Syn.AShr lhs = do
  ty <- inferTy lhs
  pure $ if ty == Syn.TyUint then TAC.TUShr else TAC.TShr
selectCompoundOp aop _ = pure (compoundOp aop)

mapBinOp :: Syn.BinOp -> TAC.BinOp
mapBinOp Syn.BAdd  = TAC.TAdd
mapBinOp Syn.BSub  = TAC.TSub
mapBinOp Syn.BMul  = TAC.TMul
mapBinOp Syn.BDiv  = TAC.TDiv
mapBinOp Syn.BMod  = TAC.TMod
mapBinOp Syn.BAnd  = TAC.TAnd
mapBinOp Syn.BOr   = TAC.TOr
mapBinOp Syn.BBand = TAC.TBand
mapBinOp Syn.BBor  = TAC.TBor
mapBinOp Syn.BBxor = TAC.TBxor
mapBinOp Syn.BShl  = TAC.TShl
mapBinOp Syn.BShr  = TAC.TShr
mapBinOp Syn.BEq   = TAC.TEq
mapBinOp Syn.BNe   = TAC.TNe
mapBinOp Syn.BLt   = TAC.TLt
mapBinOp Syn.BLe   = TAC.TLe
mapBinOp Syn.BGt   = TAC.TGt
mapBinOp Syn.BGe   = TAC.TGe

compoundOp :: Syn.AssOp -> TAC.BinOp
compoundOp Syn.AAdd  = TAC.TAdd
compoundOp Syn.ASub  = TAC.TSub
compoundOp Syn.AMul  = TAC.TMul
compoundOp Syn.ADiv  = TAC.TDiv
compoundOp Syn.AMod  = TAC.TMod
compoundOp Syn.ABand = TAC.TBand
compoundOp Syn.ABor  = TAC.TBor
compoundOp Syn.ABxor = TAC.TBxor
compoundOp Syn.AShl  = TAC.TShl
compoundOp Syn.AShr  = TAC.TShr
compoundOp Syn.AEq   = TAC.TAdd  -- unreachable; AEq handled separately

-- Short-circuit && and || lowered with branches.
lowerLogicalAnd :: Syn.Expr -> Syn.Expr -> L TAC.Operand
lowerLogicalAnd l r = do
  t <- freshTemp
  lFalse <- freshLabel "and_false"
  lEnd   <- freshLabel "and_end"
  lv <- lowerExpr l
  emit (TAC.IIfZ lv lFalse)
  rv <- lowerExpr r
  emit (TAC.IIfZ rv lFalse)
  emit (TAC.IAssign t (TAC.OConst 1))
  emit (TAC.IGoto lEnd)
  emit (TAC.ILabel lFalse)
  emit (TAC.IAssign t (TAC.OConst 0))
  emit (TAC.ILabel lEnd)
  pure (TAC.OTemp t)

lowerLogicalOr :: Syn.Expr -> Syn.Expr -> L TAC.Operand
lowerLogicalOr l r = do
  t <- freshTemp
  lTrue <- freshLabel "or_true"
  lEnd  <- freshLabel "or_end"
  lv <- lowerExpr l
  emit (TAC.IIfNZ lv lTrue)
  rv <- lowerExpr r
  emit (TAC.IIfNZ rv lTrue)
  emit (TAC.IAssign t (TAC.OConst 0))
  emit (TAC.IGoto lEnd)
  emit (TAC.ILabel lTrue)
  emit (TAC.IAssign t (TAC.OConst 1))
  emit (TAC.ILabel lEnd)
  pure (TAC.OTemp t)
