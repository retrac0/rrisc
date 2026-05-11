{-# LANGUAGE OverloadedStrings #-}
module RCC.Pass
  ( PassId(..)
  , Pass(..)
  , PassResult(..)
  , PassSet(..)
  , runPasses
  , runPassesSweep
  , runPassesUntilStable
  , parsePassToggles
  ) where

import Data.List (foldl')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T

-- | Stable identifier for a pass (used in CLI toggles and dumps).
newtype PassId = PassId { unPassId :: Text }
  deriving (Show, Eq, Ord)

data PassSet = O0 | Os | O1
  deriving (Show, Eq, Ord)

data PassResult a = PassResult
  { prOut     :: a
  , prChanged :: Bool
  } deriving (Show)

data Pass a = Pass
  { passId        :: PassId
  , passDesc      :: Text
  , passDefaultOn :: [PassSet]
  , passRun       :: a -> PassResult a
  }

-- | Apply passes in order, skipping disabled ones.
runPasses :: Map PassId Bool -> [Pass a] -> a -> a
runPasses enabled passes0 x0 = foldl' step x0 passes0
  where
    step x p =
      case Map.lookup (passId p) enabled of
        Just True -> prOut (passRun p x)
        _         -> x

-- | One full sweep over @passes@ in order; aggregate whether any enabled pass reported @prChanged@.
runPassesSweep :: Map PassId Bool -> [Pass a] -> a -> (a, Bool)
runPassesSweep enabled passes0 x0 = foldl' step (x0, False) passes0
  where
    step (x, anyCh) p =
      case Map.lookup (passId p) enabled of
        Just True ->
          let PassResult x' ch = passRun p x
           in (x', anyCh || ch)
        _ -> (x, anyCh)

-- | Repeat full sweeps until a sweep makes no change or @maxRounds@ sweeps have run.
-- Returns @(program, roundsExecuted, hitRoundCapWhileChanging)@ — the third flag is true iff the
-- last sweep still reported changes but no budget remained (possible oscillation or need more rounds).
runPassesUntilStable :: Map PassId Bool -> Int -> [Pass a] -> a -> (a, Int, Bool)
runPassesUntilStable _ maxRounds _ x0 | maxRounds <= 0 = (x0, 0, False)
runPassesUntilStable enabled maxRounds passes x0 = go x0 maxRounds 0
  where
    go x k !n
      | k <= 0 = (x, n, False)
      | otherwise =
          let (x', ch) = runPassesSweep enabled passes x
              n' = n + 1
           in if not ch
                then (x', n', False)
                else
                  if k > 1
                    then go x' (k - 1) n'
                    else (x', n', True)

-- | Parse a comma-separated list like \"+gvn,-dce\" into explicit enable/disable map.
-- Unknown pass IDs are left to the caller to validate (we still parse the shape).
parsePassToggles :: String -> Either String (Map PassId Bool)
parsePassToggles s0 =
  let parts = filter (not . null) $ map trim $ splitComma s0
   in fmap Map.fromList (traverse parseOne parts)
  where
    splitComma :: String -> [String]
    splitComma [] = [""]
    splitComma (',':xs) = "" : splitComma xs
    splitComma (x:xs) =
      case splitComma xs of
        []     -> [[x]]
        (p:ps) -> (x:p) : ps

    trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')

    parseOne :: String -> Either String (PassId, Bool)
    parseOne ('+':rest) | not (null rest) = Right (PassId (T.pack rest), True)
    parseOne ('-':rest) | not (null rest) = Right (PassId (T.pack rest), False)
    parseOne other = Left ("bad --pass toggle (use +id or -id): " <> show other)

