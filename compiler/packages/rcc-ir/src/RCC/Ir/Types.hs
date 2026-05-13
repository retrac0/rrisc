-- | Scalar / simple classification for IR values (middle-end metadata).
-- Full aggregate typing stays on frontends until lowered to word sequences.
module RCC.Ir.Types
  ( ValTy(..)
  ) where

data ValTy
  = ValInt
  | ValUint
  | ValPtr
  | ValFloat
  deriving (Show, Eq, Ord)
