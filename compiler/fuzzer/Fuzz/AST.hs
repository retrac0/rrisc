-- | Tiny C-like AST used by the rcc fuzzer.
--
-- This is *not* the full rcc AST.  It is intentionally minimal so the random
-- generator only emits constructs that:
--
--   1. Parse and type-check under both 'rcc' and host 'gcc -std=c99'.
--   2. Produce identical observable output on both targets when paired with
--      the disciplined codegen rules in "Fuzz.Gen" (see the contract there).
--
-- All values are 12-bit 'unsigned'.  Arithmetic results are masked with
-- @& 0xFFF@ at every step so the program's semantics survive the truncation
-- to the RRISC machine word.
module Fuzz.AST
  ( -- * Types
    Ty (..)
    -- * Programs
  , Program (..)
  , TopDecl (..)
  , GlobalDecl (..)
  , FuncDecl (..)
    -- * Statements
  , Stmt (..)
  , VarDecl (..)
    -- * Expressions
  , Expr (..)
  , BinOp (..)
  , UnOp (..)
  , AssOp (..)
  ) where

import Data.Text (Text)

data Ty
  = TyU                -- unsigned (12-bit on RRISC, 32-bit on gcc)
  | TyArr !Int Ty      -- array of N elements (currently only TyU elements)
  | TyPtr Ty           -- pointer to T
  deriving (Show, Eq)

newtype Program = Program { progDecls :: [TopDecl] }
  deriving (Show)

data TopDecl
  = TopGlobal GlobalDecl
  | TopFunc   FuncDecl
  deriving (Show)

data GlobalDecl = GlobalDecl
  { gName :: !Text
  , gTy   :: !Ty
  , gInit :: ![Int]   -- empty = zero-init
  } deriving (Show)

data FuncDecl = FuncDecl
  { fName   :: !Text
  , fParams :: ![(Ty, Text)]   -- parameter types/names; only TyU supported
  , fBody   :: ![Stmt]
  } deriving (Show)

data VarDecl = VarDecl
  { vName :: !Text
  , vTy   :: !Ty
  , vInit :: !(Maybe Expr)
  } deriving (Show)

data Stmt
  = SDecl   !VarDecl
  | SExpr   !Expr
  | SIf     !Expr ![Stmt] ![Stmt]   -- if (e) { ... } else { ... }
  | SWhile  !Expr ![Stmt]           -- while (e) { ... }
  | SFor    !(Maybe VarDecl) !(Maybe Expr) !(Maybe Expr) ![Stmt]
  | SBlock  ![Stmt]
  | SReturn !(Maybe Expr)
  | SBreak
  | SContinue
  -- | Print a single masked unsigned value (followed by '\n') to UART.
  -- Lowered by "Fuzz.Print" to @{ int __b[16]; itoa((expr) & 0xFFF, __b); puts(__b); }@.
  | SPrint  !Expr
  deriving (Show)

-- | Expressions are stored *without* any explicit @& 0xFFF@ wrapping.  Each
-- target's pretty-printer ("Fuzz.Print") inserts the masks it needs:
--
--   * @TargetRcc@ emits the natural C, since rcc operates on 12-bit @int@
--     and overflow is the hardware's job.
--   * @TargetHost@ wraps every overflow-prone operation in @& 0xFFF@ so the
--     32-bit gcc behaves as if it were a 12-bit machine.
--
-- This keeps the AST clean and the rcc input file readable.
data Expr
  = ELit    !Int            -- integer literal in 0..4095
  | EVar    !Text
  | EBin    !BinOp !Expr !Expr
  | EUn     !UnOp  !Expr
  | EAssign !AssOp !Expr !Expr   -- LHS is a variable or array index for now
  | ECall   !Text  ![Expr]
  | EIndex  !Expr  !Expr     -- a[i]
  | EDeref  !Expr            -- *p
  | EAddr   !Expr            -- &lv
  | EIfE    !Expr !Expr !Expr -- ternary: c ? t : e
  deriving (Show)

data BinOp
  = OAdd | OSub | OMul
  | OBand | OBor | OBxor
  | OShl | OShr
  | OEq | ONe | OLt | OLe | OGt | OGe
  | OAnd | OOr               -- short-circuit logical &&, ||
  deriving (Show, Eq)

data UnOp
  = UNeg     -- -x  (== 0 - x; emit as such for clarity in masked form)
  | UBNot    -- ~x
  | UNot     -- !x  (yields 0 or 1)
  | UPreInc  -- ++x
  | UPostInc -- x++
  | UPreDec  -- --x
  | UPostDec -- x--
  deriving (Show, Eq)

data AssOp
  = AEq                    -- =
  | AAdd | ASub | AMul     -- += -= *=
  | ABand | ABor | ABxor   -- &= |= ^=
  | AShl | AShr            -- <<= >>=
  deriving (Show, Eq)
