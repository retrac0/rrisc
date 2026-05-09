-- | Turn a valid fuzzer program into invalid C via deterministic, seed-driven
-- string mutations (one primary mutation per case).
module Fuzz.InvalidGen
  ( invalidSource
  ) where

import Data.Char (isSpace)
import Data.Text (Text)
import qualified Data.Text as T
import System.Random (StdGen, mkStdGen, randomR)

import Fuzz.Gen (GenConfig, genProgram)
import Fuzz.Print (Target (..), renderProgram)

-- | Valid program for @seed@, rendered for @rcc@, then corrupted.
invalidSource :: GenConfig -> Int -> Text
invalidSource cfg seed =
  let base = renderProgram TargetRcc (genProgram cfg seed)
      g0 = mkStdGen (seed * 19790217 + 3)
  in applyMutation g0 base

applyMutation :: StdGen -> Text -> Text
applyMutation g t
  | T.null t  = t
  | otherwise =
      let (k, g1) = randomR (0 :: Int, 7) g
      in case k of
        0 -> dropLastBrace t
        1 -> injectGarbage g1 t
        2 -> truncateFrac g1 t
        3 -> dropFirstSemicolon t
        4 -> deleteRandomLine g1 t
        5 -> swapTwoLines g1 t
        6 -> insertExtraClosingParen t
        7 -> duplicateLeadingInt t
        _ -> t

textInsertAt :: Int -> Text -> Text -> Text
textInsertAt i ins t =
  let (a, b) = T.splitAt i t
  in a <> ins <> b

dropLastBrace :: Text -> Text
dropLastBrace t =
  if "}" `T.isSuffixOf` t then T.dropEnd 1 t else t

injectGarbage :: StdGen -> Text -> Text
injectGarbage g t =
  let n = T.length t
      (i, _) = randomR (0, n) g
  in textInsertAt i (T.pack "\n@invalidtok!\n") t

truncateFrac :: StdGen -> Text -> Text
truncateFrac g t =
  let n = T.length t
      (pct, _) = randomR (30 :: Int, 70) g
      keep = max 1 (n * pct `div` 100)
  in T.take keep t

dropFirstSemicolon :: Text -> Text
dropFirstSemicolon t =
  case T.break (== ';') t of
    (a, rest) | T.null rest -> t
              | otherwise   -> a <> T.drop 1 rest

deleteRandomLine :: StdGen -> Text -> Text
deleteRandomLine g t =
  let ls = T.lines t
  in case ls of
    []   -> t
    [_]  -> t
    _    ->
      let (j, _) = randomR (0, length ls - 1) g
          ls' = take j ls ++ drop (j + 1) ls
      in T.unlines ls'

swapTwoLines :: StdGen -> Text -> Text
swapTwoLines g t =
  let ls = T.lines t
  in if length ls < 2 then t
     else
       let (i, _) = randomR (0, length ls - 2) g
           (pre, x : y : post) = splitAt i ls
       in T.unlines $ pre ++ [y, x] ++ post

insertExtraClosingParen :: Text -> Text
insertExtraClosingParen t =
  case T.findIndex (== '(') t of
    Nothing -> t <> T.singleton ')'
    Just i  -> textInsertAt (i + 1) (T.singleton ')') t

duplicateLeadingInt :: Text -> Text
duplicateLeadingInt t =
  let (ws, rest) = T.span isSpace t
  in if "int" `T.isPrefixOf` rest
       then ws <> "int int" <> T.drop 3 rest
       else "int " <> t
