{-# LANGUAGE OverloadedStrings #-}
module RCC.Ir.SSA.Verify
  ( verifySSAProg
  ) where

import Data.Text (Text)

import qualified RCC.Ir.SSA.IR as S
import qualified RCC.Ir.SSA.Prog as SP

-- | Validate CFG shape for every procedure after optimization.
verifySSAProg :: SP.SSAProg -> Either Text ()
verifySSAProg prog = go (SP.ssaProcs prog)
  where
    go [] = Right ()
    go (sp : xs) =
      case S.verifyFunc (SP.spFunc sp) of
        Left e -> Left e
        Right () -> go xs
