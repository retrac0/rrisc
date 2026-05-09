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
      , passDefaultOn = [O0, Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.normalizeCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-simplify"
      , passDesc = "CFG simplification (branch folding, unreachable removal)"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.simplifyCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-const-sccp"
      , passDesc = "Sparse conditional constant propagation"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.sccpProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-simplify-post-sccp"
      , passDesc = "CFG cleanup after SCCP"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.simplifyCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce"
      , passDesc = "Dead code elimination (incl. phi cleanup)"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-phi-simplify"
      , passDesc = "Trivial phi elimination (to copies)"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.phiSimplifyProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-copy-prop"
      , passDesc = "Copy propagation / coalescing"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.copyPropProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce-post-copy"
      , passDesc = "DCE cleanup after copy propagation"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-shrink"
      , passDesc = "Merge fall-through blocks, fold empty gotos, phis (fixpoint)"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.cfgShrinkProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-pure-cse"
      , passDesc = "Common subexpression elimination on pure ops (per basic block)"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.pureCSEProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-copy-prop-post-cse"
      , passDesc = "Copy propagation after CSE"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.copyPropProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce-post-cse"
      , passDesc = "DCE after CSE and copy"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-strength-reduce-mul"
      , passDesc = "Strength-reduce multiply by power-of-two to a shift"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.strengthReduceMulProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dce-post-strength"
      , passDesc = "DCE after strength reduction"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.dceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-tail-merge-blocks"
      , passDesc = "Merge identical basic blocks"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.tailMergeProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-normalize-post-opt"
      , passDesc = "Normalize CFG after optional CFG transforms"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.normalizeCFGProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-dispatch-balance"
      , passDesc = "Compare-chain balancing (optional lowering)"
      , passDefaultOn = []
      , passRun = \p -> let (out, ch) = SOpt.dispatchBalanceProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-cfg-thread"
      , passDesc = "Jump/branch threading"
      , passDefaultOn = [O1]
      , passRun = \p -> let (out, ch) = SOpt.branchThreadProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "ssa-float-arg-forward"
      , passDesc = "Eliminate float temp copies by arg forwarding"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.elimFloatCopiesProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "prog-dce"
      , passDesc = "Whole-program procedure DCE (callgraph reachability)"
      , passDefaultOn = [Os, O1]
      , passRun = \p -> let (out, ch) = SOpt.eliminateDeadCodeProg p in PassResult out ch
      }
  , Pass
      { passId = PassId "global-dedupe-float-rodata"
      , passDesc = "Deduplicate float rodata globals"
      , passDefaultOn = [Os, O1]
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
  , alias "ssa-shrink" "ssa-cfg-shrink" SOpt.cfgShrinkProg
  , alias "ssa-cse" "ssa-pure-cse" SOpt.pureCSEProg
  , alias "ssa-strength-mul" "ssa-strength-reduce-mul" SOpt.strengthReduceMulProg
  , alias "ssa-tail-merge" "ssa-tail-merge-blocks" SOpt.tailMergeProg
  , alias "ssa-dispatch" "ssa-dispatch-balance" SOpt.dispatchBalanceProg
  , alias "ssa-phi" "ssa-phi-simplify" SOpt.phiSimplifyProg
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

