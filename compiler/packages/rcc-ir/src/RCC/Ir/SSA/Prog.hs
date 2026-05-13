module RCC.Ir.SSA.Prog
  ( SSAProc(..)
  , SSAProg(..)
  ) where

import Data.Map.Strict (Map)

import qualified RCC.Ir.SSA.IR as S
import qualified RCC.Ir.TAC as TAC

data SSAProc = SSAProc
  { spFunc   :: S.Func
  , spLocSzs :: Map TAC.Temp Int
  } deriving (Show, Eq)

data SSAProg = SSAProg
  { ssaGlobals :: [TAC.Global]
  , ssaProcs   :: [SSAProc]
  } deriving (Show)

