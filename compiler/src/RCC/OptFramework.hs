{-# LANGUAGE OverloadedStrings #-}
module RCC.OptFramework
  ( optimizeWith
  , defaultTacPasses
  , elimTrivialAssignsProg
  ) where

import Data.Map.Strict (Map)

import RCC.Pass
import qualified RCC.TAC as TAC

-- | Drop @x = x@ three-address assignments (no-op after register allocation shapes).
elimTrivialAssignsProc :: TAC.Proc -> (TAC.Proc, Bool)
elimTrivialAssignsProc p =
  let is0 = TAC.procInstrs p
      trivial (TAC.IAssign t (TAC.OTemp t')) = t == t'
      trivial _ = False
      is' = filter (not . trivial) is0
   in (p { TAC.procInstrs = is' }, length is' /= length is0)

-- | Apply 'elimTrivialAssignsProc' to every procedure.
elimTrivialAssignsProg :: TAC.TACProg -> (TAC.TACProg, Bool)
elimTrivialAssignsProg prog =
  let (ps, chs) = unzip (map elimTrivialAssignsProc (TAC.tacProcs prog))
   in (prog { TAC.tacProcs = ps }, or chs)

defaultTacPasses :: [Pass TAC.TACProg]
defaultTacPasses =
  [ Pass
      { passId = PassId "tac-trivial-assign"
      , passDesc = "Remove self-assignments (x = x)"
      , passDefaultOn = [Os, O1]
      , passRun = \p ->
          let (out, ch) = elimTrivialAssignsProg p
           in PassResult out ch
      }
  ]

optimizeWith :: Map PassId Bool -> [Pass TAC.TACProg] -> TAC.TACProg -> TAC.TACProg
optimizeWith enabled passes prog =
  runPasses enabled passes prog

