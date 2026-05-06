module RCC.Optimize
  ( optimize
  ) where

import qualified RCC.TAC as TAC

-- | Run all optimization passes over a TAC program.
-- Each pass is a TACProg -> TACProg transformation; add passes to the list
-- as they are implemented.
optimize :: TAC.TACProg -> TAC.TACProg
optimize = foldr (.) id passes
  where
    passes = []  -- placeholder: constantFold, deadCode, copyProp, ...
