{-# LANGUAGE OverloadedStrings #-}
module RCC.OptFrameworkSSA
  ( optimizeSSAWith
  , defaultSsaPasses
  ) where

import Data.Map.Strict (Map)

import RCC.Pass
import qualified RCC.SSA.Optimize as SOpt
import qualified RCC.SSA.Prog as SP

defaultSsaPasses :: [Pass SP.SSAProg]
defaultSsaPasses =
  -- Canonical SSA pipeline pass IDs (stable, user-facing):
  [ Pass
      { passId = PassId "ssa-cfg-normalize"
      , passDesc = "Recompute preds/succs and drop unreachable blocks"
      , passDefaultOn = [O0, Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.normalizeCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-simplify"
      , passDesc = "CFG simplification (branch folding, unreachable removal)"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.simplifyCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-const-sccp"
      , passDesc = "Sparse conditional constant propagation"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.sccpProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-simplify-post-sccp"
      , passDesc = "CFG cleanup after SCCP"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.simplifyCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce"
      , passDesc = "Dead code elimination (incl. phi cleanup)"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-copy-prop"
      , passDesc = "Copy propagation / coalescing"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.copyPropProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce-post-copy"
      , passDesc = "DCE cleanup after copy propagation"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-thread"
      , passDesc = "Jump/branch threading (O2)"
      , passDefaultOn = [O2]
      , passRun = \p -> let (out, ch) = SOpt.branchThreadProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-float-arg-forward"
      , passDesc = "Eliminate float temp copies by arg forwarding"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.elimFloatCopiesProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "prog-dce"
      , passDesc = "Whole-program procedure DCE (callgraph reachability)"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.eliminateDeadCodeProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "global-dedupe-float-rodata"
      , passDesc = "Deduplicate float rodata globals"
      , passDefaultOn = [Os, O2]
      , passRun = \p -> let (out, ch) = SOpt.dedupeFloatRoDataProg p in PassResult out ch
      }

  -- Back-compat aliases for older IDs (all default-off).
  , alias "ssa-normalize-cfg" "ssa-cfg-normalize" SOpt.normalizeCFGProg
  , alias "ssa-simplifycfg" "ssa-cfg-simplify" SOpt.simplifyCFGProg
  , alias "ssa-sccp" "ssa-const-sccp" SOpt.sccpProg
  , alias "ssa-simplifycfg-2" "ssa-cfg-simplify-post-sccp" SOpt.simplifyCFGProg
  , alias "ssa-copy" "ssa-copy-prop" SOpt.copyPropProg
  , alias "ssa-dce-2" "ssa-dce-post-copy" SOpt.dceProg
  , alias "ssa-branch-thread" "ssa-cfg-thread" SOpt.branchThreadProg
  , alias "ssa-float-copy" "ssa-float-arg-forward" SOpt.elimFloatCopiesProg
  , alias "ssa-callgraph-dce" "prog-dce" SOpt.eliminateDeadCodeProg
  , alias "ssa-dedupe-float-rodata" "global-dedupe-float-rodata" SOpt.dedupeFloatRoDataProg
  ]
  where
    alias pidOld pidNew f =
      Pass
        { passId = PassId pidOld
        , passDesc = "DEPRECATED alias for --pass +" <> pidNew
        , passDefaultOn = []
        , passRun = \p -> let (out, ch) = f p in PassResult out ch
        }

optimizeSSAWith :: Map PassId Bool -> [Pass SP.SSAProg] -> SP.SSAProg -> SP.SSAProg
optimizeSSAWith enabled passes prog =
  runPasses enabled passes prog

