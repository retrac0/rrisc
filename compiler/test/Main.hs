{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import RCC.CliParse (parseIntArg)
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.HUnit (testCase, (@=?), assertEqual)

main :: IO ()
main =
  defaultMain $
    testGroup
      "rcc"
      [ testGroup
          "CliParse.parseIntArg"
          [ testCase "octal 0o100" $ parseIntArg "0o100" @=? Right 64
          , testCase "decimal" $ parseIntArg "42" @=? Right 42
          , testCase "hex" $ parseIntArg "0xff" @=? Right 255
          , testCase "reject garbage" $ do
              case parseIntArg "12xyz" of
                Left _ -> pure ()
                Right n -> assertEqual "expected failure" (show n) "unexpected success"
          ]
      ]
