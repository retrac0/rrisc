module Main (main) where

import Test.Tasty (defaultMain, testGroup)

-- | Placeholder entrypoint so @cabal test@ stays wired; SSA checks run via
-- @RCC_VERIFY_SSA@ in @run_tests.py@.
main :: IO ()
main = defaultMain (testGroup "rcc" [])
