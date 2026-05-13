-- | Checked AST lowering: 'lowerToSSA' emits SSA-shaped basic blocks (no TAC in bodies).
-- 'lower' derives flat TAC only via @ToTACProg . lowerToSSA@ for tools and codegen prep.
module RCC.Frontend.C.LowerToSSA
  ( lower
  , lowerToSSA
  , lowerToSSAPlain
  , tacCfgToSSA
  , tacProcToSSA
  , RawBuilder(..)
  , ProcBuild(..)
  ) where

import Control.Monad (forM, forM_, when, unless)
import Control.Monad.State.Strict
import Data.List (foldl', nub)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T

import qualified RCC.Frontend.C.Sema   as Sema
import qualified RCC.Frontend.C.Syntax as Syn
import qualified RCC.Ir.TAC    as TAC
import qualified RCC.Ir.SSA.CFG as C
import qualified RCC.Ir.SSA.Dom as Dom
import qualified RCC.Ir.SSA.IR as Ssa
import qualified RCC.Ir.SSA.Prog as SP
import qualified RCC.Ir.SSA.ToTACProg as ToTACProg
import RCC.Ir.DataLayout (DataLayout(..))
import RCC.Frontend.C.Layout (cTySizeWords, structFieldOffsetWords)
import RCC.Frontend.C.FloatWords (encodeFloatLiteralWords)

-- ---------------------------------------------------------------------------
-- Lowering monad

-- | In-progress basic block (instruction list is reversed between label boundaries).
data RawBuilder = RawBuilder
  { bldrId    :: C.BlockId
  , bldrLabel :: Maybe TAC.Label
  , bldrRev   :: [Ssa.Instr]
  }

-- | One lowered function: ordered basic blocks + metadata for TAC export and codegen.
data ProcBuild = ProcBuild
  { pbName   :: TAC.Label
  , pbParams :: [TAC.Temp]
  , pbRaws   :: [C.RawBlock]
  , pbLocSzs :: Map TAC.Temp Int
  }

data LS = LS
  { lsTemp        :: Int
  , lsLabel       :: Int
  , lsRawAcc      :: [C.RawBlock]                       -- completed blocks in order
  , lsRawCur      :: RawBuilder
  , lsRawNextId   :: Int
  , lsLocals      :: Map Text Syn.Ty                    -- current func locals + params
  , lsGlobals     :: Map Text (Syn.Ty, Bool)
  , lsStructs     :: Map Text [Syn.Field]
  , lsFuncs       :: Map Text (Syn.Ty, [(Syn.Ty, Text)])
  , lsLoopStack   :: [(TAC.Label, TAC.Label)]           -- (continue, break)
  , lsProcs       :: [ProcBuild]                        -- reversed
  , lsGlobalDefs  :: [TAC.Global]                       -- reversed
  , lsConstLocals :: Map Text Ssa.Value                 -- const local aggregates -> rodata addr
  , lsDataLayout  :: !DataLayout
  }

emptyLS :: DataLayout -> LS
emptyLS dl = LS 0 0 []
    (RawBuilder (C.BlockId 0) Nothing []) 1
    Map.empty Map.empty Map.empty Map.empty [] [] [] Map.empty dl

type L = State LS

flushBlock :: C.RawTerm -> RawBuilder -> C.RawBlock
flushBlock rt b =
  C.RawBlock (bldrId b) (bldrLabel b) (reverse (bldrRev b)) rt

terminateWith :: C.UTerm -> L ()
terminateWith ut = do
  cur <- gets lsRawCur
  acc <- gets lsRawAcc
  n <- gets lsRawNextId
  let raw = flushBlock (C.URT ut) cur
      bid = C.BlockId n
  modify $ \s -> s
    { lsRawAcc = acc ++ [raw]
    , lsRawCur = RawBuilder bid Nothing []
    , lsRawNextId = n + 1
    }

emitSsa :: Ssa.Instr -> L ()
emitSsa i = modify $ \s ->
  let c = lsRawCur s
   in s { lsRawCur = c { bldrRev = i : bldrRev c } }

emitLabel :: TAC.Label -> L ()
emitLabel l = do
  cur <- gets lsRawCur
  acc <- gets lsRawAcc
  n <- gets lsRawNextId
  let acc1 = acc ++ [flushBlock (C.URT (C.UTGoto C.JFall)) cur]
      bid = C.BlockId n
  modify $ \s -> s
    { lsRawAcc = acc1
    , lsRawCur = RawBuilder bid (Just l) []
    , lsRawNextId = n + 1
    }

emitIfZ :: Ssa.Value -> TAC.Label -> L ()
emitIfZ v lab = terminateWith (C.UTIfZ v (C.JLab lab) C.JFall)

emitIfNZ :: Ssa.Value -> TAC.Label -> L ()
emitIfNZ v lab = terminateWith (C.UTIfNZ v (C.JLab lab) C.JFall)

emitGoto :: TAC.Label -> L ()
emitGoto lab = terminateWith (C.UTGoto (C.JLab lab))

emitReturn :: Maybe Ssa.Value -> L ()
emitReturn mv = terminateWith (C.UTReturn mv)

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

addConstLocal :: Text -> Ssa.Value -> L ()
addConstLocal name v =
  modify $ \s -> s { lsConstLocals = Map.insert name v (lsConstLocals s) }

structOffset :: Text -> Text -> L Int
structOffset sname fname = do
  dl <- gets lsDataLayout
  ss <- gets lsStructs
  case structFieldOffsetWords dl ss sname fname of
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

lower :: DataLayout -> Sema.CheckedProg -> TAC.TACProg
lower dl = ToTACProg.toTACProg . lowerToSSA dl

-- | Lower checked AST to SSA (basic blocks from lowering + Cytron-style SSA on the CFG).
lowerToSSA :: DataLayout -> Sema.CheckedProg -> SP.SSAProg
lowerToSSA dl (Syn.Prog decls) =
  let final = execState (lowerProg decls) (emptyLS dl)
      procs =
        [ SP.SSAProc
            { SP.spFunc =
                case C.cfgFromRawBlockList (pbName p) (pbParams p) (pbRaws p) >>= tacCfgToSSA of
                  Left err -> error ("lowerToSSA: " ++ err)
                  Right f  -> f
            , SP.spLocSzs = pbLocSzs p
            }
        | p <- reverse (lsProcs final)
        ]
   in SP.SSAProg (reverse (lsGlobalDefs final)) procs

-- | Like 'lowerToSSA' but skips Cytron @phi@ insertion (CFG bodies stay in lowered form).
lowerToSSAPlain :: DataLayout -> Sema.CheckedProg -> SP.SSAProg
lowerToSSAPlain dl (Syn.Prog decls) =
  let final = execState (lowerProg decls) (emptyLS dl)
      procs =
        [ SP.SSAProc
            { SP.spFunc =
                case C.cfgFromRawBlockList (pbName p) (pbParams p) (pbRaws p) of
                  Left err -> error ("lowerToSSAPlain: " ++ err)
                  Right cfg -> C.cfgToSsaFunc cfg
            , SP.spLocSzs = pbLocSzs p
            }
        | p <- reverse (lsProcs final)
        ]
   in SP.SSAProg (reverse (lsGlobalDefs final)) procs

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
  dl <- gets lsDataLayout
  ss <- gets lsStructs
  let name  = Syn.vdName vd
      ty    = Syn.vdTy vd
      sz    = cTySizeWords dl ss ty
      isC   = Syn.vdConst vd
      initVals = case ty of
        Syn.TyFloat -> case Syn.vdInit vd of
          Just (Syn.IExpr (Syn.EFloatLit _ d)) -> encodeFloatLiteralWords dl d
          _                                    -> replicate (dlFloatWords dl) 0
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
    put s0 { lsTemp = 0
           , lsRawAcc = []
           , lsRawCur = RawBuilder (C.BlockId 0) Nothing []
           , lsRawNextId = 1
           , lsLocals = Map.empty
           , lsLoopStack = [], lsConstLocals = Map.empty }
    mapM_ (\(ty, n) -> addLocal n ty) (Syn.fdParams fd)
    mapM_ lowerStmt body
    -- Implicit return at end of body (0 if int, void otherwise).
    sf <- get
    let alreadyReturned = case lsRawAcc sf of
          [] -> False
          xs -> case C.rbTerm (last xs) of
            C.URT (C.UTReturn _) -> True
            _                     -> False
    unless alreadyReturned $
      if Syn.fdRetTy fd == Syn.TyVoid
        then emitReturn Nothing
        else emitReturn (Just (Ssa.VConst 0))
    sg <- get
    let dl        = lsDataLayout sg
        ss        = lsStructs sg
        paramSet  = Map.fromList (map (\(ty, n) -> (n, ty)) (Syn.fdParams fd))
        locSzs    = Map.fromList
          [ (name, sz)
          | (name, ty) <- Map.toList (lsLocals sg)
          , Map.notMember name paramSet
          , Map.notMember name (lsConstLocals sg)
          , let sz = cTySizeWords dl ss ty
          , sz > 1
          ]
        rbs = lsRawAcc sg
        pb  = ProcBuild (Syn.fdName fd) (map snd (Syn.fdParams fd)) rbs locSzs
    put sg { lsTemp        = lsTemp s0
           , lsRawAcc      = lsRawAcc s0
           , lsRawCur      = lsRawCur s0
           , lsRawNextId   = lsRawNextId s0
           , lsLocals      = lsLocals s0
           , lsLoopStack   = lsLoopStack s0
           , lsConstLocals = lsConstLocals s0
           , lsProcs       = pb : lsProcs sg
           }
lowerTop _ = pure ()

-- ---------------------------------------------------------------------------
-- Statements

lowerStmt :: Syn.Stmt -> L ()
lowerStmt (Syn.SBlock _ ss)   = mapM_ lowerStmt ss
lowerStmt s@(Syn.SVarDecl vd) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  let name = Syn.vdName vd
      ty   = Syn.vdTy vd
  addLocal name ty
  case Syn.vdInit vd of
    Nothing ->
      case ty of
        Syn.TyArray  _ _ -> emitSsa (Ssa.IComment ("alloclocal " <> name))
        Syn.TyStruct _ _ -> emitSsa (Ssa.IComment ("alloclocal " <> name))
        Syn.TyFloat      -> emitSsa (Ssa.IComment ("alloclocal " <> name))
        _                -> pure ()
    Just (Syn.IList es) ->
      if Syn.vdConst vd && all isLitExpr es
        then do  -- const aggregate with all-literal init -> rodata global
          dl <- gets lsDataLayout
          ss <- gets lsStructs
          let sz       = cTySizeWords dl ss ty
              initVals = [n | Syn.ELit _ n <- es]
          synName <- freshLabel ("const_" <> name)
          modify $ \ls -> ls { lsGlobalDefs = TAC.Global synName sz initVals True
                                              : lsGlobalDefs ls }
          addConstLocal name (Ssa.VAddr synName)
        else initAggrOnStack name ty es
    Just (Syn.IExpr e) ->
      case ty of
        Syn.TyArray  _ _ -> emitSsa (Ssa.IComment ("alloclocal " <> name))
        Syn.TyStruct _ _ -> emitSsa (Ssa.IComment ("alloclocal " <> name))
        Syn.TyFloat -> do
          emitSsa (Ssa.IComment ("alloclocal " <> name))
          src <- lowerExpr e
          emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [Ssa.VLocalAddr name, src]))
        _ -> do
          v <- lowerExpr e
          emitSsa (Ssa.IDef name (Ssa.OCopy v))
lowerStmt s@(Syn.SExpr _ e)   = do
  emitSsa (Ssa.IComment (prettyStmt s))
  () <$ lowerExpr e
lowerStmt s@(Syn.SIf _ c t me) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  cv <- lowerExpr c
  case me of
    Nothing -> do
      lEnd <- freshLabel "endif"
      emitIfZ cv lEnd
      lowerStmt t
      emitLabel lEnd
    Just el -> do
      lElse <- freshLabel "else"
      lEnd  <- freshLabel "endif"
      emitIfZ cv lElse
      lowerStmt t
      emitGoto lEnd
      emitLabel lElse
      lowerStmt el
      emitLabel lEnd
lowerStmt s@(Syn.SWhile _ c body) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  lHead <- freshLabel "while"
  lEnd  <- freshLabel "endwhile"
  emitLabel lHead
  cv <- lowerExpr c
  emitIfZ cv lEnd
  pushLoop (lHead, lEnd)
  lowerStmt body
  popLoop
  emitGoto lHead
  emitLabel lEnd
lowerStmt s@(Syn.SFor _ ini c step body) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  case ini of
    Syn.FIDecl vd -> lowerStmt (Syn.SVarDecl vd)
    Syn.FIExpr Nothing -> pure ()
    Syn.FIExpr (Just e) -> () <$ lowerExpr e
  lHead <- freshLabel "for"
  lCont <- freshLabel "forcont"
  lEnd  <- freshLabel "endfor"
  emitLabel lHead
  case c of
    Nothing -> pure ()
    Just ce -> do
      cv <- lowerExpr ce
      emitIfZ cv lEnd
  pushLoop (lCont, lEnd)
  lowerStmt body
  popLoop
  emitLabel lCont
  case step of
    Nothing -> pure ()
    Just se -> () <$ lowerExpr se
  emitGoto lHead
  emitLabel lEnd
lowerStmt s@(Syn.SReturn _ Nothing) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  emitReturn Nothing
lowerStmt s@(Syn.SReturn _ (Just e)) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  v <- lowerExpr e
  emitReturn (Just v)
lowerStmt s@(Syn.SBreak _) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((_, lEnd):_) -> emitGoto lEnd
    []            -> pure ()
lowerStmt s@(Syn.SContinue _) = do
  emitSsa (Ssa.IComment (prettyStmt s))
  ls <- gets lsLoopStack
  case ls of
    ((lCont, _):_) -> emitGoto lCont
    []             -> pure ()
lowerStmt (Syn.SAsmInline _ txt) = emitSsa (Ssa.IEffect (Ssa.OTargetAsm txt))

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
  emitSsa (Ssa.IComment ("alloclocal " <> name))
  ss <- gets lsStructs
  dl <- gets lsDataLayout
  -- C99 6.7.8/19: an aggregate initialiser with fewer items than the
  -- aggregate has elements zero-fills the trailing positions.  We model
  -- that here by writing every slot explicitly, falling back to a zero
  -- constant when the source ran out of expressions.  This matters for
  -- arrays like @int v[4] = { 0 };@ where the user wrote one initialiser
  -- but expects all four words to be zero.
  --
  -- Currently this zero-fill only fires for 1-word elements (scalars
  -- and pointers).  Arrays of multi-word elements (e.g. @float v[4]@)
  -- would need an aggregate copy of an all-zero source rather than a
  -- single 'OConst' store; we keep the explicit-only path for those
  -- until @float@ arrays show up in the test corpus.
  case ty of
    Syn.TyArray inner n
      | cTySizeWords dl ss inner == 1 -> do
          let nExpr = length es
          forM_ [0 .. n - 1] $ \i -> do
            val <- if i < nExpr
                     then lowerExpr (es !! i)
                     else pure (Ssa.VConst 0)
            storeAtOff name i val
    _ -> do
      let elemSz = case ty of
            Syn.TyArray inner _ -> cTySizeWords dl ss inner
            _                   -> 1
      forM_ (zip [0..] es) $ \(i, e) -> do
        ev <- lowerExpr e
        storeAtOff' name (i * elemSz) ev
  where
    storeAtOff n i val = storeAtOff' n i val
    storeAtOff' n off val = do
      addrOp <- if off == 0
                  then pure (Ssa.VLocalAddr n)
                  else do
                    at <- freshTemp
                    emitSsa (Ssa.IDef at (Ssa.OBin TAC.TAdd (Ssa.VLocalAddr n) (Ssa.VConst off)))
                    pure (Ssa.VVar at)
      emitSsa (Ssa.IStore addrOp val)

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
-- lowerAddr / lowerExpr produce 'Ssa.Value' (no TAC.Operand in lowering).

lowerExpr :: Syn.Expr -> L Ssa.Value
lowerExpr (Syn.ELit _ n)       = pure (Ssa.VConst n)
lowerExpr (Syn.EFloatLit _ d)  = do
  dl <- gets lsDataLayout
  name <- freshLabel "flit"
  modify $ \ls -> ls { lsGlobalDefs = TAC.Global name (dlFloatWords dl) (encodeFloatLiteralWords dl d) True
                                      : lsGlobalDefs ls }
  pure (Ssa.VAddr name)
lowerExpr (Syn.EString _ txt)  = do
  name <- freshLabel "str"
  let chars = map fromEnum (T.unpack txt) ++ [0]
      sz    = length chars
  modify $ \ls -> ls { lsGlobalDefs = TAC.Global name sz chars True : lsGlobalDefs ls }
  pure (Ssa.VAddr name)
lowerExpr (Syn.EVar _ name)    = do
  cl <- gets lsConstLocals
  case Map.lookup name cl of
    Just v -> pure v
    Nothing -> do
      loc <- isLocal name
      if loc
        then do
          ls <- gets lsLocals
          case Map.lookup name ls of
            Just (Syn.TyArray  _ _) -> pure (Ssa.VLocalAddr name)
            Just (Syn.TyStruct _ _) -> pure (Ssa.VLocalAddr name)
            Just Syn.TyFloat        -> pure (Ssa.VLocalAddr name)
            _                       -> pure (Ssa.VVar name)
        else do
          glb <- isGlobal name
          if glb
            then do
              gs <- gets lsGlobals
              let ty = fst (gs Map.! name)
              case ty of
                Syn.TyArray  _ _ -> pure (Ssa.VAddr name)
                Syn.TyStruct _ _ -> pure (Ssa.VAddr name)
                Syn.TyFloat      -> pure (Ssa.VAddr name)
                _ -> do
                  t <- freshTemp
                  emitSsa (Ssa.IDef t (Ssa.OLoad (Ssa.VAddr name)))
                  pure (Ssa.VVar t)
            else pure (Ssa.VAddr name)
lowerExpr (Syn.EUnary _ op e)  = do
  et <- inferTy e
  v  <- lowerExpr e
  case (op, et) of
    (Syn.UDeref, Syn.TyPtr Syn.TyFloat) -> pure v
    _ -> do
      t  <- freshTemp
      if op == Syn.UNeg && et == Syn.TyFloat
        then do
          addLocal t Syn.TyFloat
          emitSsa (Ssa.IComment ("alloclocal " <> t))
          emitSsa (Ssa.IEffect (Ssa.OCall "__fneg" [Ssa.VLocalAddr t, v]))
          pure (Ssa.VLocalAddr t)
        else do
          case op of
            Syn.UNeg    -> emitSsa (Ssa.IDef t (Ssa.OUn TAC.TNeg v))
            Syn.UNot    -> emitSsa (Ssa.IDef t (Ssa.OUn TAC.TNot v))
            Syn.UBNot   -> emitSsa (Ssa.IDef t (Ssa.OUn TAC.TBNot v))
            Syn.UDeref  -> emitSsa (Ssa.IDef t (Ssa.OLoad v))
            Syn.UAddrOf -> do
              addr <- lowerAddr e
              emitSsa (Ssa.IDef t (Ssa.OCopy addr))
            Syn.UPreInc -> do
              addr1 <- freshTemp
              emitSsa (Ssa.IDef addr1 (Ssa.OBin TAC.TAdd v (Ssa.VConst 1)))
              assignTo e (Ssa.VVar addr1)
              emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VVar addr1)))
            Syn.UPreDec -> do
              addr1 <- freshTemp
              emitSsa (Ssa.IDef addr1 (Ssa.OBin TAC.TSub v (Ssa.VConst 1)))
              assignTo e (Ssa.VVar addr1)
              emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VVar addr1)))
          pure (Ssa.VVar t)
lowerExpr (Syn.EBinary _ op l r) = do
  lt <- inferTy l
  case op of
    Syn.BAnd -> lowerLogicalAnd l r
    Syn.BOr  -> lowerLogicalOr  l r
    _ | lt == Syn.TyFloat -> lowerFloatBinOp op l r
    _ -> do
      lv    <- lowerExpr l
      rv    <- lowerExpr r
      t     <- freshTemp
      tacOp <- selectBinOp op l r
      emitSsa (Ssa.IDef t (Ssa.OBin tacOp lv rv))
      pure (Ssa.VVar t)
lowerExpr (Syn.EAssign _ aop lhs rhs) = do
  lt <- inferTy lhs
  case aop of
    Syn.AEq | lt == Syn.TyFloat -> do
      dst <- lowerAddr lhs
      src <- lowerExpr rhs
      emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [dst, src]))
      pure src
    Syn.AEq -> do
      rv <- lowerExpr rhs
      assignTo lhs rv
      pure rv
    _ | lt == Syn.TyFloat -> do
      let synOp = compoundToSynBinOp aop
      result <- lowerExpr (Syn.EBinary (Syn.exprSpan lhs) synOp lhs rhs)
      dst    <- lowerAddr lhs
      emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [dst, result]))
      pure result
    _ -> do
      lv    <- lowerExpr lhs
      rv    <- lowerExpr rhs
      t     <- freshTemp
      tacOp <- selectCompoundOp aop lhs
      emitSsa (Ssa.IDef t (Ssa.OBin tacOp lv rv))
      assignTo lhs (Ssa.VVar t)
      pure (Ssa.VVar t)
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
      emitSsa (Ssa.IDef t (Ssa.OLoad addr))
      pure (Ssa.VVar t)
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
      pure (Ssa.VVar t)
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
      pure (Ssa.VVar t)
lowerExpr (Syn.ECall _ name args) = do
  argOps <- mapM lowerExpr args
  t <- freshTemp
  emitSsa (Ssa.IDef t (Ssa.OCall name argOps))
  pure (Ssa.VVar t)
lowerExpr (Syn.ETernary _ cond t f) = do
  cv     <- lowerExpr cond
  result <- freshTemp
  lElse  <- freshLabel "tern_else"
  lEnd   <- freshLabel "tern_end"
  emitIfZ cv lElse
  tv <- lowerExpr t
  emitSsa (Ssa.IDef result (Ssa.OCopy tv))
  emitGoto lEnd
  emitLabel lElse
  fv <- lowerExpr f
  emitSsa (Ssa.IDef result (Ssa.OCopy fv))
  emitLabel lEnd
  pure (Ssa.VVar result)
lowerExpr (Syn.ECompoundLit _ ty es) = do
  name <- freshTemp
  addLocal name ty
  case ty of
    Syn.TyArray  _ _ -> initAggrOnStack name ty es
    Syn.TyStruct _ _ -> initAggrOnStack name ty es
    _ -> case es of
           [e] -> do { v <- lowerExpr e; emitSsa (Ssa.IDef name (Ssa.OCopy v)) }
           _   -> pure ()
  pure (Ssa.VLocalAddr name)
lowerExpr (Syn.ECast _ toTy e)  = do
  fromTy <- inferTy e
  case (fromTy, toTy) of
    (Syn.TyFloat, Syn.TyInt) -> do
      src <- lowerExpr e
      t   <- freshTemp
      emitSsa (Ssa.IDef t (Ssa.OCall "__ftoi" [src]))
      pure (Ssa.VVar t)
    (Syn.TyFloat, Syn.TyUint) -> do
      src <- lowerExpr e
      t   <- freshTemp
      emitSsa (Ssa.IDef t (Ssa.OCall "__ftoi" [src]))
      pure (Ssa.VVar t)
    (_, Syn.TyFloat) | fromTy /= Syn.TyFloat -> do
      iv  <- lowerExpr e
      t   <- freshTemp
      addLocal t Syn.TyFloat
      emitSsa (Ssa.IComment ("alloclocal " <> t))
      emitSsa (Ssa.IEffect (Ssa.OCall "__itof" [Ssa.VLocalAddr t, iv]))
      pure (Ssa.VLocalAddr t)
    _ -> lowerExpr e
lowerExpr (Syn.ESizeof _ arg)   = do
  dl <- gets lsDataLayout
  ss <- gets lsStructs
  case arg of
    Left ty -> pure (Ssa.VConst (cTySizeWords dl ss ty))
    Right e -> do
      ty <- inferTy e
      pure (Ssa.VConst (cTySizeWords dl ss ty))
lowerExpr (Syn.EPostfix _ pop e) = do
  ov <- lowerExpr e
  orig <- freshTemp
  emitSsa (Ssa.IDef orig (Ssa.OCopy ov))
  newv <- freshTemp
  case pop of
    Syn.PostInc -> emitSsa (Ssa.IDef newv (Ssa.OBin TAC.TAdd ov (Ssa.VConst 1)))
    Syn.PostDec -> emitSsa (Ssa.IDef newv (Ssa.OBin TAC.TSub ov (Ssa.VConst 1)))
  assignTo e (Ssa.VVar newv)
  pure (Ssa.VVar orig)

readField :: Ssa.Value -> Int -> Syn.Ty -> L Ssa.Value
readField baseAddr off fty = do
  addr <- if off == 0
            then pure baseAddr
            else do
              a <- freshTemp
              emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd baseAddr (Ssa.VConst off)))
              pure (Ssa.VVar a)
  case fty of
    Syn.TyArray _ _   -> pure addr
    Syn.TyStruct _ _  -> pure addr
    Syn.TyFloat       -> pure addr
    _ -> do
      t <- freshTemp
      emitSsa (Ssa.IDef t (Ssa.OLoad addr))
      pure (Ssa.VVar t)

indexAddr :: Syn.Expr -> Syn.Expr -> L Ssa.Value
indexAddr arr idx = do
  arrTy <- inferTy arr
  ss    <- gets lsStructs
  dl    <- gets lsDataLayout
  let elemSz = case arrTy of
        Syn.TyPtr   inner   -> cTySizeWords dl ss inner
        Syn.TyArray inner _ -> cTySizeWords dl ss inner
        _                   -> 1
  baseAddr <- lowerExpr arr
  iv       <- lowerExpr idx
  scaledIv <- if elemSz <= 1
                then pure iv
                else do
                  si <- freshTemp
                  emitSsa (Ssa.IDef si (Ssa.OBin TAC.TMul iv (Ssa.VConst elemSz)))
                  pure (Ssa.VVar si)
  a <- freshTemp
  emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd baseAddr scaledIv))
  pure (Ssa.VVar a)

lowerAddr :: Syn.Expr -> L Ssa.Value
lowerAddr (Syn.EVar _ name) = do
  cl <- gets lsConstLocals
  case Map.lookup name cl of
    Just v -> pure v
    Nothing -> do
      glb <- isGlobal name
      if glb
        then pure (Ssa.VAddr name)
        else pure (Ssa.VLocalAddr name)
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
          emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd addr (Ssa.VConst off)))
          pure (Ssa.VVar a)
    _ -> pure (Ssa.VConst 0)
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
          emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd pv (Ssa.VConst off)))
          pure (Ssa.VVar a)
    _ -> pure (Ssa.VConst 0)
lowerAddr e = lowerExpr e

assignTo :: Syn.Expr -> Ssa.Value -> L ()
assignTo (Syn.EVar _ name) rv = do
  loc <- isLocal name
  if loc
    then do
      ls <- gets lsLocals
      case Map.lookup name ls of
        Just Syn.TyFloat ->
          emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [Ssa.VLocalAddr name, rv]))
        _ -> emitSsa (Ssa.IDef name (Ssa.OCopy rv))
    else do
      glb <- isGlobal name
      when glb $ do
        gs <- gets lsGlobals
        case Map.lookup name gs of
          Just (Syn.TyFloat, _) ->
            emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [Ssa.VAddr name, rv]))
          _ -> emitSsa (Ssa.IStore (Ssa.VAddr name) rv)
assignTo (Syn.EUnary _ Syn.UDeref e) rv = do
  pv <- lowerExpr e
  emitSsa (Ssa.IStore pv rv)
assignTo (Syn.EIndex _ arr idx) rv = do
  arrTy <- inferTy arr
  let elemTy = case arrTy of
        Syn.TyPtr   inner   -> inner
        Syn.TyArray inner _ -> inner
        _                   -> Syn.TyInt
  addr <- indexAddr arr idx
  case elemTy of
    Syn.TyFloat -> emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [addr, rv]))
    _           -> emitSsa (Ssa.IStore addr rv)
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
                    emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd addr (Ssa.VConst off)))
                    pure (Ssa.VVar a)
      case ftyp of
        Syn.TyFloat -> emitSsa (Ssa.IEffect (Ssa.OCall "__fcopy" [target, rv]))
        _           -> emitSsa (Ssa.IStore target rv)
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
                    emitSsa (Ssa.IDef a (Ssa.OBin TAC.TAdd pv (Ssa.VConst off)))
                    pure (Ssa.VVar a)
      emitSsa (Ssa.IStore target rv)
    _ -> pure ()
assignTo _ _ = pure ()

-- Re-derive the type of an expression.
inferTy :: Syn.Expr -> L Syn.Ty
-- Integer literals follow C's "first type that fits" rule for hex / octal /
-- binary literals: a value that doesn't fit in signed @int@ becomes
-- @unsigned@.  With rcc's 12-bit @int@ (range -2048..2047) that means
-- literals in [2048, 4095] are typed @unsigned@.  This matters for
-- right-shift (signed @>>@ is arithmetic, unsigned @>>@ is logical) and for
-- the usual arithmetic conversions in comparisons; cf. spec.md §3.
inferTy (Syn.ELit _ n)        = pure $ if n > 2047 then Syn.TyUint else Syn.TyInt
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
inferTy (Syn.EBinary _ op l r) = case op of
  Syn.BSub -> do
    lt <- inferTy l
    rt <- inferTy r
    case (lt, rt) of
      (Syn.TyPtr _, Syn.TyPtr _) -> pure Syn.TyInt
      _                          -> arithCommonTy lt rt
  Syn.BAdd  -> arithCommonTyOf l r
  Syn.BMul  -> arithCommonTyOf l r
  Syn.BDiv  -> arithCommonTyOf l r
  Syn.BMod  -> arithCommonTyOf l r
  Syn.BBand -> arithCommonTyOf l r
  Syn.BBor  -> arithCommonTyOf l r
  Syn.BBxor -> arithCommonTyOf l r
  -- Shift result type is the (promoted) type of the LHS only.
  Syn.BShl  -> inferTy l
  Syn.BShr  -> inferTy l
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

lowerFloatBinOp :: Syn.BinOp -> Syn.Expr -> Syn.Expr -> L Ssa.Value
lowerFloatBinOp op l r = do
  la <- lowerExpr l
  ra <- lowerExpr r
  case op of
    Syn.BAdd -> floatArith "__fadd" la ra
    Syn.BSub -> floatArith "__fsub" la ra
    Syn.BMul -> floatArith "__fmul" la ra
    Syn.BDiv -> floatArith "__fdiv" la ra
    _        -> floatCmp op la ra

floatArith :: Text -> Ssa.Value -> Ssa.Value -> L Ssa.Value
floatArith fn la ra = do
  res <- freshTemp
  addLocal res Syn.TyFloat
  emitSsa (Ssa.IComment ("alloclocal " <> res))
  emitSsa (Ssa.IEffect (Ssa.OCall fn [Ssa.VLocalAddr res, la, ra]))
  pure (Ssa.VLocalAddr res)

floatCmp :: Syn.BinOp -> Ssa.Value -> Ssa.Value -> L Ssa.Value
floatCmp op la ra = do
  cmpT <- freshTemp
  emitSsa (Ssa.IDef cmpT (Ssa.OCall "__fcmp" [la, ra]))
  t <- freshTemp
  let tacOp = case op of
        Syn.BEq -> TAC.TEq
        Syn.BNe -> TAC.TNe
        Syn.BLt -> TAC.TLt
        Syn.BLe -> TAC.TLe
        Syn.BGt -> TAC.TGt
        Syn.BGe -> TAC.TGe
        _       -> TAC.TEq
  emitSsa (Ssa.IDef t (Ssa.OBin tacOp (Ssa.VVar cmpT) (Ssa.VConst 0)))
  pure (Ssa.VVar t)

compoundToSynBinOp :: Syn.AssOp -> Syn.BinOp
compoundToSynBinOp Syn.AAdd  = Syn.BAdd
compoundToSynBinOp Syn.ASub  = Syn.BSub
compoundToSynBinOp Syn.AMul  = Syn.BMul
compoundToSynBinOp Syn.ADiv  = Syn.BDiv
compoundToSynBinOp _         = Syn.BAdd  -- fallback; caller ensures float-valid ops

-- ---------------------------------------------------------------------------
-- Helpers

-- True iff the type behaves as unsigned for the usual arithmetic conversions.
-- Pointers compare and arithmetic-convert as unsigned (the memory address
-- space is unsigned).
isUnsignedTy :: Syn.Ty -> Bool
isUnsignedTy Syn.TyUint    = True
isUnsignedTy (Syn.TyPtr _) = True
isUnsignedTy _             = False

-- C's "usual arithmetic conversions" applied to the two operand types of an
-- arithmetic / bitwise binary operator.  With only one integer width, the
-- rule reduces to: if either operand is unsigned, the common type is
-- unsigned; otherwise it is signed @int@.  Pointer-typed operands are not
-- normally combined with arithmetic operators except via pointer
-- arithmetic; we treat them as unsigned, matching how rcc handles
-- @int + ptr@-style expressions.
arithCommonTy :: Syn.Ty -> Syn.Ty -> L Syn.Ty
arithCommonTy lt rt = pure $
  if isUnsignedTy lt || isUnsignedTy rt then Syn.TyUint else Syn.TyInt

arithCommonTyOf :: Syn.Expr -> Syn.Expr -> L Syn.Ty
arithCommonTyOf l r = do
  lt <- inferTy l
  rt <- inferTy r
  arithCommonTy lt rt

-- Choose signed vs unsigned TAC op for a relational / shift node, applying
-- C's usual arithmetic conversions: a comparison is unsigned iff *either*
-- operand is unsigned.  Shifts are special — only the LHS type determines
-- whether @>>@ is logical or arithmetic.
selectBinOp :: Syn.BinOp -> Syn.Expr -> Syn.Expr -> L TAC.BinOp
selectBinOp op lExpr rExpr = do
  lTy <- inferTy lExpr
  rTy <- inferTy rExpr
  let uBoth = isUnsignedTy lTy || isUnsignedTy rTy
      uLhs  = isUnsignedTy lTy
  pure $ case op of
    Syn.BLt  | uBoth -> TAC.TULt
    Syn.BLe  | uBoth -> TAC.TULe
    Syn.BGt  | uBoth -> TAC.TUGt
    Syn.BGe  | uBoth -> TAC.TUGe
    Syn.BShr | uLhs  -> TAC.TUShr
    -- Unsigned divide / modulo: skip the sign-handling preamble of the
    -- signed routines.  Required for correctness on values with bit 11
    -- set, where the signed routines would interpret a 12-bit unsigned
    -- as a negative number.
    Syn.BDiv | uBoth -> TAC.TUDiv
    Syn.BMod | uBoth -> TAC.TUMod
    _                -> mapBinOp op

selectCompoundOp :: Syn.AssOp -> Syn.Expr -> L TAC.BinOp
selectCompoundOp Syn.AShr lhs = do
  ty <- inferTy lhs
  pure $ if ty == Syn.TyUint then TAC.TUShr else TAC.TShr
selectCompoundOp Syn.ADiv lhs = do
  ty <- inferTy lhs
  pure $ if ty == Syn.TyUint then TAC.TUDiv else TAC.TDiv
selectCompoundOp Syn.AMod lhs = do
  ty <- inferTy lhs
  pure $ if ty == Syn.TyUint then TAC.TUMod else TAC.TMod
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
lowerLogicalAnd :: Syn.Expr -> Syn.Expr -> L Ssa.Value
lowerLogicalAnd l r = do
  t <- freshTemp
  lFalse <- freshLabel "and_false"
  lEnd   <- freshLabel "and_end"
  lv <- lowerExpr l
  emitIfZ lv lFalse
  rv <- lowerExpr r
  emitIfZ rv lFalse
  emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VConst 1)))
  emitGoto lEnd
  emitLabel lFalse
  emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VConst 0)))
  emitLabel lEnd
  pure (Ssa.VVar t)

lowerLogicalOr :: Syn.Expr -> Syn.Expr -> L Ssa.Value
lowerLogicalOr l r = do
  t <- freshTemp
  lTrue <- freshLabel "or_true"
  lEnd  <- freshLabel "or_end"
  lv <- lowerExpr l
  emitIfNZ lv lTrue
  rv <- lowerExpr r
  emitIfNZ rv lTrue
  emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VConst 0)))
  emitGoto lEnd
  emitLabel lTrue
  emitSsa (Ssa.IDef t (Ssa.OCopy (Ssa.VConst 1)))
  emitLabel lEnd
  pure (Ssa.VVar t)

-- ---------------------------------------------------------------------------
-- TAC → SSA (CFG + dominance; inlined from former RCC.Ir.SSA.FromLower)

type SsaBVar = TAC.Temp

data SSABuildState = SSABuildState
  { rsNext    :: Int
  , rsStacks  :: Map SsaBVar [Text]
  , rsPhiArgs :: Map (Ssa.BlockId, SsaBVar) (Map Ssa.BlockId Ssa.Value)
  , rsBlocks  :: Map Ssa.BlockId Ssa.Block
  }

type MSSA = State SSABuildState

ssaPhiBaseVar :: Text -> SsaBVar
ssaPhiBaseVar = T.takeWhile (/= '#')

ssaFresh :: SsaBVar -> MSSA Text
ssaFresh v = do
  n <- gets rsNext
  modify $ \s -> s { rsNext = n + 1 }
  pure (v <> "#" <> T.pack (show n))

ssaPush :: SsaBVar -> Text -> MSSA ()
ssaPush v nm = modify $ \s ->
  s { rsStacks = Map.insertWith (++) v [nm] (rsStacks s) }

ssaPop1 :: SsaBVar -> MSSA ()
ssaPop1 v = modify $ \s ->
  s { rsStacks = Map.adjust (\xs -> case xs of { [] -> []; (_:ys) -> ys }) v (rsStacks s) }

ssaTop :: SsaBVar -> MSSA Text
ssaTop v = do
  st <- gets rsStacks
  case Map.lookup v st of
    Just (x:_) -> pure x
    _          -> pure v

-- | SSA names defined in a block (pre-phi / lowered body).
ssaDefsInSsaBlock :: [Ssa.Instr] -> Set SsaBVar
ssaDefsInSsaBlock = foldl' step Set.empty
  where
    step acc (Ssa.IDef nm _) = Set.insert (ssaPhiBaseVar nm) acc
    step acc _               = acc

renameValue :: Ssa.Value -> MSSA Ssa.Value
renameValue (Ssa.VConst n)     = pure (Ssa.VConst n)
renameValue (Ssa.VAddr l)      = pure (Ssa.VAddr l)
renameValue (Ssa.VLocalAddr t) = pure (Ssa.VLocalAddr t)
renameValue (Ssa.VVar x)       = Ssa.VVar <$> ssaTop (ssaPhiBaseVar x)

renameOp :: Ssa.Op -> MSSA Ssa.Op
renameOp (Ssa.OBin op a b)   = Ssa.OBin op <$> renameValue a <*> renameValue b
renameOp (Ssa.OUn op a)      = Ssa.OUn op <$> renameValue a
renameOp (Ssa.OCopy v)       = Ssa.OCopy <$> renameValue v
renameOp (Ssa.OLoad v)       = Ssa.OLoad <$> renameValue v
renameOp (Ssa.OCall f vs)    = Ssa.OCall f <$> mapM renameValue vs
renameOp (Ssa.OTargetAsm t)        = pure (Ssa.OTargetAsm t)

renameSsaInstr :: Ssa.Instr -> MSSA [Ssa.Instr]
renameSsaInstr (Ssa.IComment t)    = pure [Ssa.IComment t]
renameSsaInstr (Ssa.IStore a b)    = do
  a' <- renameValue a
  b' <- renameValue b
  pure [Ssa.IStore a' b']
renameSsaInstr (Ssa.IEffect op)    = do
  op' <- renameOp op
  pure [Ssa.IEffect op']
renameSsaInstr (Ssa.IDef nm op)    = do
  op' <- renameOp op
  let base = ssaPhiBaseVar nm
  nm' <- ssaFresh base
  ssaPush base nm'
  pure [Ssa.IDef nm' op']
renameSsaInstr (Ssa.IPhi _ _) =
  error "renameSsaInstr: unexpected phi in lowered block"

cfgTermToSSA :: C.Term -> MSSA Ssa.Term
cfgTermToSSA (C.TGoto bid) = pure (Ssa.TGoto (Ssa.BlockId (C.unBlockId bid)))
cfgTermToSSA (C.TReturn mv) =
  Ssa.TReturn <$> traverse renameValue mv
-- C.TIfZ: first successor is the zero-taken target; Ssa.TBr is (if v/=0 then fst else snd).
cfgTermToSSA (C.TIfZ v tz fnz) = do
  vv <- renameValue v
  pure (Ssa.TBr vv
          (Ssa.BlockId (C.unBlockId fnz))
          (Ssa.BlockId (C.unBlockId tz)))
cfgTermToSSA (C.TIfNZ v tnz tz) = do
  vv <- renameValue v
  pure (Ssa.TBr vv
          (Ssa.BlockId (C.unBlockId tnz))
          (Ssa.BlockId (C.unBlockId tz)))
cfgTermToSSA (C.TIfCmp op a b t f) = do
  va <- renameValue a
  vb <- renameValue b
  pure (Ssa.TBrCmp False op va vb
          (Ssa.BlockId (C.unBlockId t)) (Ssa.BlockId (C.unBlockId f)))
cfgTermToSSA (C.TIfNCmp op a b t f) = do
  va <- renameValue a
  vb <- renameValue b
  pure (Ssa.TBrCmp True op va vb
          (Ssa.BlockId (C.unBlockId t)) (Ssa.BlockId (C.unBlockId f)))

-- | Cytron-style SSA on a CFG whose block bodies are already lowered 'Ssa.Instr's.
tacCfgToSSA :: C.CFG -> Either String Ssa.Func
tacCfgToSSA cfg =
  let di = Dom.computeDominators cfg
      df = Dom.dominanceFrontiers cfg di
      blocks = C.cfgBlocks cfg
      vars = Set.unions [ssaDefsInSsaBlock (C.bBody b) | b <- Map.elems blocks]
      phiPlacements = ssaPlacePhis vars blocks df
      entry = C.cfgEntry cfg
      children = Dom.domTreeChildren cfg di
      initState = SSABuildState 0 Map.empty Map.empty Map.empty
      stFinal = execState (ssaRenameAll cfg children phiPlacements entry) initState
      blocksFilled = ssaFillPhiArgs (rsPhiArgs stFinal) (rsBlocks stFinal)
      f = Ssa.Func (C.cfgName cfg) (C.cfgParams cfg)
                (Ssa.BlockId (C.unBlockId entry))
                blocksFilled
   in case Ssa.verifyFunc f of
        Left t -> Left (T.unpack t)
        Right () -> Right f

-- | Convert a flat TAC procedure to SSA (partition into blocks, then 'tacCfgToSSA').
tacProcToSSA :: TAC.Proc -> Either String Ssa.Func
tacProcToSSA proc = C.buildCFG proc >>= tacCfgToSSA

ssaPlacePhis :: Set TAC.Temp
          -> Map C.BlockId C.Block
          -> Map C.BlockId (Set C.BlockId)
          -> Map C.BlockId [TAC.Temp]
ssaPlacePhis vars blocks df =
  foldl' insVar Map.empty (Set.toList vars)
  where
    defsMap = Map.map (ssaDefsInSsaBlock . C.bBody) blocks
    insVar acc v =
      let defBlocks = [b | (b, ds) <- Map.toList defsMap, v `Set.member` ds]
          work0 = defBlocks
          go placed [] = placed
          go placed (x:ws) =
            let frontier = Set.toList (Map.findWithDefault Set.empty x df)
                (placed', ws') = foldl' (step x) (placed, ws) frontier
             in go placed' ws'
          step _ (pl, ws) y =
            if v `elem` Map.findWithDefault [] y pl
              then (pl, ws)
              else
                let pl' = Map.insertWith (++) y [v] pl
                    ws' = if y `elem` defBlocks then ws else y : ws
                 in (pl', ws')
       in go acc work0

-- | Merge phi predecessor maps; duplicate predecessor with differing values is a compiler bug.
phiInnerUnion :: Map Ssa.BlockId Ssa.Value -> Map Ssa.BlockId Ssa.Value -> Map Ssa.BlockId Ssa.Value
phiInnerUnion = Map.unionWithKey mergePhiEdge
  where
    mergePhiEdge predBlk new old
      | new == old = old
      | otherwise =
          error $
            "RCC.Frontend.C.LowerToSSA.phiInnerUnion: conflicting phi operand from predecessor "
              ++ show predBlk ++ ": " ++ show (new, old)

ssaRenameAll :: C.CFG
          -> Map C.BlockId [C.BlockId]
          -> Map C.BlockId [SsaBVar]
          -> C.BlockId
          -> MSSA ()
ssaRenameAll cfg children phiMap bid = do
  let b = C.cfgBlocks cfg Map.! bid
      varsHere = Map.findWithDefault [] bid phiMap

  -- Phi defs at start of block
  phiDefs <- forM varsHere $ \v -> do
    nm <- ssaFresh v
    ssaPush v nm
    pure (v, nm)

  -- Lower block body (already SSA-shaped; rename defs/uses)
  bodyInstrs <- fmap concat (mapM renameSsaInstr (C.bBody b))
  term <- cfgTermToSSA (C.bTerm b)

  let sbid = Ssa.BlockId (C.unBlockId bid)
      preds = [Ssa.BlockId (C.unBlockId p) | p <- nub (C.bPreds b)]
      succs = [Ssa.BlockId (C.unBlockId s) | s <- nub (C.bSuccs b)]
      phis = [Ssa.IPhi nm [] | (_, nm) <- phiDefs]
      sb = Ssa.Block
        { Ssa.bId = sbid
        , Ssa.bLabel = C.bLabel b
        , Ssa.bInstrs = phis ++ bodyInstrs
        , Ssa.bTerm = term
        , Ssa.bPreds = preds
        , Ssa.bSuccs = succs
        }
  modify $ \s -> s { rsBlocks = Map.insert sbid sb (rsBlocks s) }

  -- Add phi arguments for successors from current environment (after body).
  forM_ (nub (C.bSuccs b)) $ \succBid -> do
    let succVars = Map.findWithDefault [] succBid phiMap
        succSbid = Ssa.BlockId (C.unBlockId succBid)
    forM_ succVars $ \v -> do
      nm <- ssaTop v
      let val = Ssa.VVar nm
      modify $ \s ->
        s { rsPhiArgs =
              Map.insertWith
                phiInnerUnion
                (succSbid, v)
                (Map.singleton sbid val)
                (rsPhiArgs s)
          }

  -- Recurse into dominator tree children
  forM_ (Map.findWithDefault [] bid children) $ \c ->
    ssaRenameAll cfg children phiMap c

  -- Pop defs introduced in this block (phis + defs)
  let defs = map fst phiDefs ++ concatMap ssaInstrDefVars bodyInstrs
  mapM_ ssaPop1 defs

ssaInstrDefVars :: Ssa.Instr -> [SsaBVar]
ssaInstrDefVars (Ssa.IDef nm _) = [ssaPhiBaseVar nm]
ssaInstrDefVars _             = []

ssaFillPhiArgs :: Map (Ssa.BlockId, SsaBVar) (Map Ssa.BlockId Ssa.Value)
            -> Map Ssa.BlockId Ssa.Block
            -> Map Ssa.BlockId Ssa.Block
ssaFillPhiArgs phiArgs blocks =
  Map.map fillOne blocks
  where
    fillOne b =
      let preds = Ssa.bPreds b
          fillInstr (Ssa.IPhi nm _) =
            let v = ssaPhiBaseVar nm
                m = Map.findWithDefault Map.empty (Ssa.bId b, v) phiArgs
                edges = [ (p, Map.findWithDefault (Ssa.VVar v) p m) | p <- preds ]
             in Ssa.IPhi nm edges
          fillInstr x = x
       in b { Ssa.bInstrs = map fillInstr (Ssa.bInstrs b) }
