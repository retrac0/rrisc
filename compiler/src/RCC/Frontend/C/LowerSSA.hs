module RCC.Frontend.C.LowerSSA
  ( lowerSSA
  , lowerSSAPlain
  ) where

import qualified RCC.Frontend.C.LowerToSSA as LowerToSSA
import qualified RCC.Ir.SSA.Prog as SP
import qualified RCC.Frontend.C.Sema as Sema
import RCC.Ir.DataLayout (DataLayout)

-- | Lower checked AST to SSA (basic blocks during lowering; Cytron SSA on the CFG).
lowerSSA :: DataLayout -> Sema.CheckedProg -> SP.SSAProg
lowerSSA = LowerToSSA.lowerToSSA

-- | Lower without Cytron SSA (no @phi@); for @-O0@ / unoptimized pipeline.
lowerSSAPlain :: DataLayout -> Sema.CheckedProg -> SP.SSAProg
lowerSSAPlain = LowerToSSA.lowerToSSAPlain
