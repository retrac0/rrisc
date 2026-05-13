module RCC.Ir.TAC
  ( Temp
  , Label
  , Operand(..)
  , BinOp(..)
  , UnOp(..)
  , Instr(..)
  , Proc(..)
  , Global(..)
  , TACProg(..)
  ) where

import Data.Map.Strict (Map)
import Data.Text (Text)

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
  | TUDiv | TUMod                -- unsigned divide / modulo
  deriving (Show, Eq, Ord)

data UnOp
  = TNeg | TNot | TBNot
  deriving (Show, Eq, Ord)

data Instr
  = ILabel   Label
  | IComment Text                    -- source-level annotation (emitted as ;; in asm)
  | IAssign  Temp Operand
  | IBinOp   Temp BinOp Operand Operand
  | IUnOp    Temp UnOp  Operand
  | ILoad    Temp Operand            -- t = *op
  | IStore   Operand Operand         -- *addr = val
  | IGoto    Label
  -- Branch on comparison without materializing a boolean temp.
  -- If the comparison evaluates true, jump to Label.
  | IIfCmp   BinOp Operand Operand Label
  -- If the comparison evaluates false, jump to Label.
  | IIfNCmp  BinOp Operand Operand Label
  | IIfNZ    Operand Label
  | IIfZ     Operand Label
  | ICall    (Maybe Temp) Label [Operand]
  | IReturn  (Maybe Operand)
  | IAllocLocal Temp    -- reserve stack space for a local array/struct; no code emitted
  | -- | Verbatim assembly for backends that support this extension (RRISC today).
    ITargetAsm Text
  deriving (Show, Eq)

data Global = Global
  { globalName  :: Label
  , globalSize  :: Int
  , globalInit  :: [Int]
  , globalConst :: Bool
  } deriving (Show)

data Proc = Proc
  { procName    :: Label
  , procParams  :: [Temp]
  , procInstrs  :: [Instr]
  , procLocSzs  :: Map Temp Int  -- local name -> word count for multi-word locals
  } deriving (Show)

data TACProg = TACProg
  { tacGlobals :: [Global]
  , tacProcs   :: [Proc]
  } deriving (Show)
