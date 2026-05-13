{-# LANGUAGE OverloadedStrings #-}
-- | C frontend driver: parse, semantic check, and lower to SSA.
module RCC.Frontend.C.Compile
  ( parseAndCheck
  , lowerCheckedToSSA
  ) where

import Data.Text (Text)

import RCC.Error (Diagnostic)
import qualified RCC.Frontend.C.Parser as Parser
import qualified RCC.Frontend.C.Sema as Sema
import qualified RCC.Frontend.C.LowerSSA as LowerSSA
import qualified RCC.Ir.SSA.Prog as SP
import RCC.Ir.DataLayout (DataLayout)
import qualified RCC.Pipeline as Pipe

-- | Parse a translation unit and run the C semantic checker.
parseAndCheck :: FilePath -> Text -> Either Diagnostic Sema.CheckedProg
parseAndCheck fp src = do
  ast <- Parser.parseProgram fp src
  Sema.check ast

-- | Lower a checked program to SSA using the given word layout and optimization level.
lowerCheckedToSSA :: DataLayout -> Pipe.OptLevel -> Sema.CheckedProg -> SP.SSAProg
lowerCheckedToSSA dl ol checked =
  case ol of
    Pipe.O0 -> LowerSSA.lowerSSAPlain dl checked
    _       -> LowerSSA.lowerSSA dl checked
