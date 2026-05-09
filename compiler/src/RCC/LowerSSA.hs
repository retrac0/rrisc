module RCC.LowerSSA
  ( lowerSSA
  , lowerSSAPlain
  ) where

import qualified RCC.LowerToSSA as LowerToSSA
import qualified RCC.SSA.Prog as SP
import qualified RCC.Sema as Sema

-- | Lower checked AST to SSA (basic blocks during lowering; Cytron SSA on the CFG).
lowerSSA :: Sema.CheckedProg -> SP.SSAProg
lowerSSA = LowerToSSA.lowerToSSA

-- | Lower without Cytron SSA (no @phi@); for @-O0@ / unoptimized pipeline.
lowerSSAPlain :: Sema.CheckedProg -> SP.SSAProg
lowerSSAPlain = LowerToSSA.lowerToSSAPlain
