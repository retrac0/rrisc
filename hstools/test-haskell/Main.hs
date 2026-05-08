{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Data.Text (Text)
import qualified Data.Text as T
import RRISC.Obj.Format (
  ObjectFile (..),
  SecRecord (..),
  Section (..),
  formatObjParseError,
  objVersion,
  parseObject,
  renderObject,
 )
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.HUnit (assertEqual, assertFailure, testCase)

minimalObj :: ObjectFile
minimalObj =
  ObjectFile
    { ofVersion = objVersion
    , ofSources = ["test.s"]
    , ofSections = [Section "text" [RecWord 1, RecWord 0o7777]]
    }

main :: IO ()
main =
  defaultMain $
    testGroup
      "hstools"
      [ testCase "object render/parse round-trip" $ do
          let txt = renderObject minimalObj :: Text
          case parseObject "roundtrip.o" txt of
            Left e -> assertFailure (T.unpack (formatObjParseError e))
            Right o -> assertEqual "parsed object" minimalObj o
      ]
