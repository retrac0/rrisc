module RCC.Syntax
  ( Ty(..)
  , Prog(..)
  , TopDecl(..)
  , FuncDecl(..)
  , VarDecl(..)
  , StructDecl(..)
  , Field(..)
  , Block
  , Stmt(..)
  , ForInit(..)
  , Init(..)
  , Expr(..)
  , UnOp(..)
  , PostOp(..)
  , BinOp(..)
  , AssOp(..)
  , exprSpan
  , stmtSpan
  ) where

import Data.Text (Text)
import RCC.Error (Pos, Span)

-- | Types as written in source.
-- TyStruct carries the span of the struct-name token for error reporting.
data Ty
  = TyInt                -- int
  | TyUint               -- unsigned
  | TyVoid               -- void
  | TyPtr    Ty          -- T *
  | TyArray  Ty Int      -- T [N]
  | TyStruct Span Text   -- struct S  (Span = position of the name token)
  deriving (Show)

-- Equality ignores source spans.
instance Eq Ty where
  TyInt          == TyInt          = True
  TyUint         == TyUint         = True
  TyVoid         == TyVoid         = True
  TyPtr a        == TyPtr b        = a == b
  TyArray a n    == TyArray b m    = a == b && n == m
  TyStruct _ a   == TyStruct _ b   = a == b
  _              == _              = False

newtype Prog = Prog { progDecls :: [TopDecl] }
  deriving (Show)

data TopDecl
  = TDFunc    FuncDecl
  | TDVar     VarDecl
  | TDStruct  StructDecl
  | TDTypedef Span Ty Text
  deriving (Show)

data FuncDecl = FuncDecl
  { fdSpan   :: Span
  , fdRetTy  :: Ty
  , fdName   :: Text
  , fdParams :: [(Ty, Text)]
  , fdBody   :: Maybe Block   -- Nothing = prototype
  } deriving (Show)

data VarDecl = VarDecl
  { vdSpan    :: Span
  , vdNamePos :: Pos    -- position of the variable-name token
  , vdConst   :: Bool
  , vdTy      :: Ty
  , vdName    :: Text
  , vdInit    :: Maybe Init
  } deriving (Show)

data StructDecl = StructDecl
  { sdSpan   :: Span
  , sdName   :: Text
  , sdFields :: [Field]
  } deriving (Show)

data Field = Field
  { fieldTy   :: Ty
  , fieldName :: Text
  } deriving (Show)

type Block = [Stmt]

data Stmt
  = SBlock     Span [Stmt]
  | SVarDecl   VarDecl
  | SExpr      Span Expr
  | SIf        Span Expr Stmt (Maybe Stmt)
  | SWhile     Span Expr Stmt
  | SFor       Span ForInit (Maybe Expr) (Maybe Expr) Stmt
  | SReturn    Span (Maybe Expr)
  | SBreak     Span
  | SContinue  Span
  | SAsmInline Span Text
  deriving (Show)

data ForInit
  = FIDecl VarDecl
  | FIExpr (Maybe Expr)
  deriving (Show)

data Init
  = IExpr Expr
  | IList [Expr]
  deriving (Show)

data Expr
  = ELit          Span Int
  | EVar          Span Text
  | EUnary        Span UnOp Expr
  | EBinary       Span BinOp Expr Expr
  | EAssign       Span AssOp Expr Expr
  | EIndex        Span Expr Expr
  | EField        Span Expr Text
  | EArrow        Span Expr Text
  | ECall         Span Text [Expr]
  | ECast         Span Ty Expr
  | ESizeof       Span (Either Ty Expr)
  | EPostfix      Span PostOp Expr
  | ETernary      Span Expr Expr Expr   -- cond ? then : else
  | ECompoundLit  Span Ty [Expr]        -- (type){e1, e2, ...}
  deriving (Show)

data UnOp
  = UNeg    -- unary -
  | UNot    -- logical !
  | UBNot   -- bitwise ~
  | UDeref  -- * (dereference)
  | UAddrOf -- & (address-of)
  | UPreInc -- prefix ++
  | UPreDec -- prefix --
  deriving (Show, Eq)

data PostOp
  = PostInc -- x++
  | PostDec -- x--
  deriving (Show, Eq)

data BinOp
  = BAdd | BSub | BMul | BDiv | BMod       -- arithmetic
  | BAnd | BOr                              -- logical &&  ||
  | BBand | BBor | BBxor                   -- bitwise &  |  ^
  | BShl | BShr                            -- shifts
  | BEq | BNe | BLt | BLe | BGt | BGe     -- comparisons
  deriving (Show, Eq)

data AssOp
  = AEq                                    -- =
  | AAdd | ASub | AMul | ADiv | AMod       -- += -= *= /= %=
  | ABand | ABor | ABxor                   -- &= |= ^=
  | AShl | AShr                            -- <<= >>=
  deriving (Show, Eq)

exprSpan :: Expr -> Span
exprSpan e = case e of
  ELit         s _       -> s
  EVar         s _       -> s
  EUnary       s _ _     -> s
  EBinary      s _ _ _   -> s
  EAssign      s _ _ _   -> s
  EIndex       s _ _     -> s
  EField       s _ _     -> s
  EArrow       s _ _     -> s
  ECall        s _ _     -> s
  ECast        s _ _     -> s
  ESizeof      s _       -> s
  EPostfix     s _ _     -> s
  ETernary     s _ _ _   -> s
  ECompoundLit s _ _     -> s

stmtSpan :: Stmt -> Span
stmtSpan s = case s of
  SBlock     sp _       -> sp
  SVarDecl   vd         -> vdSpan vd
  SExpr      sp _       -> sp
  SIf        sp _ _ _   -> sp
  SWhile     sp _ _     -> sp
  SFor       sp _ _ _ _ -> sp
  SReturn    sp _       -> sp
  SBreak     sp         -> sp
  SContinue  sp         -> sp
  SAsmInline sp _       -> sp
