-- | Word-level memory layout assumptions for lowering and data emission.
-- Targets / frontends pick a concrete 'DataLayout'; the IR itself stays agnostic.
module RCC.Ir.DataLayout
  ( DataLayout(..)
  , rrisc12DataLayout
  ) where

-- | Sizes are in addressable words (e.g. 12-bit cells on RRISC).
data DataLayout = DataLayout
  { dlIntWords   :: !Int
  , dlUintWords  :: !Int
  , dlVoidWords  :: !Int
  , dlFloatWords :: !Int
  , dlPtrWords   :: !Int
  } deriving (Show, Eq)

-- | Layout used by the stock RRISC rcc port (matches legacy @Sema.tySize@ defaults).
rrisc12DataLayout :: DataLayout
rrisc12DataLayout = DataLayout
  { dlIntWords   = 1
  , dlUintWords  = 1
  , dlVoidWords  = 0
  , dlFloatWords = 4
  , dlPtrWords   = 1
  }
