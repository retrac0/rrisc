module RCC.SSA.Prog
  ( SSAProc(..)
  , SSAProg(..)
  ) where

import Data.Map.Strict (Map)

import qualified RCC.SSA.IR as S
import qualified RCC.TAC as TAC

data SSAProc = SSAProc
  { spFunc   :: S.Func
  , spLocSzs :: Map TAC.Temp Int
  } deriving (Show, Eq)

data SSAProg = SSAProg
  { ssaGlobals :: [TAC.Global]
  , ssaProcs   :: [SSAProc]
  } deriving (Show)

