{-# LANGUAGE OverloadedStrings #-}
-- | Multi-backend entry (currently only RRISC is wired up).
module RCC.Target
  ( TargetId(..)
  , Target(..)
  , rriscTarget
  , defaultRriscCodegenOpts
  ) where

import Data.Text (Text)

import RCC.Ir.DataLayout (DataLayout, rrisc12DataLayout)
import qualified RCC.Ir.TAC as TAC
import qualified RCC.Target.Rrisc.Codegen as RCG

data TargetId = TIDRrisc
  deriving (Show, Eq)

-- | Backend bundle: layout assumptions the middle-end used when lowering, plus emission.
data Target = Target
  { targetId           :: !TargetId
  , targetDataLayout   :: !DataLayout
  , emitTacProgramText :: RCG.CodegenOpts -> TAC.TACProg -> Text
  }

defaultRriscCodegenOpts :: RCG.CodegenOpts
defaultRriscCodegenOpts = RCG.defaultOpts

-- | Stock RRISC 12-bit toolchain target (@rrisc12DataLayout@ + @RCC.Target.Rrisc.Codegen@).
rriscTarget :: Target
rriscTarget = Target
  { targetId = TIDRrisc
  , targetDataLayout = rrisc12DataLayout
  , emitTacProgramText = RCG.codegen
  }
