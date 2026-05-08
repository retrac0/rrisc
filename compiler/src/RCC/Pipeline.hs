{-# LANGUAGE OverloadedStrings #-}
module RCC.Pipeline
  ( OptLevel(..)
  , Pipeline(..)
  , defaultPipeline
  , pipelineEnabledMap
  ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import RCC.Pass (Pass(..), PassId)
import qualified RCC.Pass as Pass

data OptLevel = O0 | Os | O2
  deriving (Show, Eq)

data Pipeline a = Pipeline
  { plLevel :: OptLevel
  , plPasses :: [Pass a]
  }

defaultPipeline :: OptLevel -> [Pass a] -> Pipeline a
defaultPipeline lvl ps = Pipeline lvl ps

pipelineEnabledMap :: Pipeline a -> Map PassId Bool
pipelineEnabledMap (Pipeline lvl ps) =
  let set = case lvl of
        O0 -> Pass.O0
        Os -> Pass.Os
        O2 -> Pass.O2
   in Map.fromList
        [ (passId p, set `elem` passDefaultOn p)
        | p <- ps
        ]

