-- | CFG-shaped lowering state for AST → basic blocks.
--
-- The lowering monad ('Control.Monad.State.Strict') and all statement / expression
-- rules live in "RCC.LowerToSSA"; this module exists so block accumulation types are
-- addressable without pulling in the full lowering implementation elsewhere.
module RCC.LowerEmitSSA
  ( RawBuilder(..)
  , ProcBuild(..)
  ) where

import RCC.LowerToSSA (ProcBuild(..), RawBuilder(..))
