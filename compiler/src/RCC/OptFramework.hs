{-# LANGUAGE OverloadedStrings #-}
module RCC.OptFramework
  ( optimizeWith
  , defaultTacPasses
  , elimTrivialAssignsProg
  , tacPeepholeProg
  ) where

import Data.Map.Strict (Map)

import RCC.Pass
import qualified RCC.Ir.TAC as TAC

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

-- | Drop @goto L@ when the next instruction is @L:@ (fall-through).
elimGotoToNextLabelOnce :: [TAC.Instr] -> ([TAC.Instr], Bool)
elimGotoToNextLabelOnce [] = ([], False)
elimGotoToNextLabelOnce [x] = ([x], False)
elimGotoToNextLabelOnce (TAC.IGoto l : TAC.ILabel m : rest)
  | l == m =
      let (is', ch) = elimGotoToNextLabelOnce (TAC.ILabel m : rest)
       in (is', True || ch)
elimGotoToNextLabelOnce (x : xs) =
  let (xs', ch) = elimGotoToNextLabelOnce xs
   in (x : xs', ch)

elimGotoToNextLabel :: [TAC.Instr] -> ([TAC.Instr], Bool)
elimGotoToNextLabel is0 = go is0 False
  where
    go is ch =
      let (is', ch1) = elimGotoToNextLabelOnce is
          ch' = ch || ch1
       in if ch1 then go is' ch' else (is', ch')

-- | Pure local algebraic simplifications on three-address ops.
simplifyPureBinOp :: TAC.Instr -> TAC.Instr
simplifyPureBinOp (TAC.IBinOp t TAC.TAdd a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TAdd (TAC.OConst 0) a) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TSub a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TMul a (TAC.OConst 1)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TMul (TAC.OConst 1) a) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBor a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBor (TAC.OConst 0) a) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBand a (TAC.OConst (-1))) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBand (TAC.OConst (-1)) a) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBxor a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TBxor (TAC.OConst 0) a) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TShl a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TShr a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp (TAC.IBinOp t TAC.TUShr a (TAC.OConst 0)) = TAC.IAssign t a
simplifyPureBinOp i = i

mapPureBinOpSimp :: [TAC.Instr] -> ([TAC.Instr], Bool)
mapPureBinOpSimp is =
  let is' = map simplifyPureBinOp is
   in (is', is' /= is)

tacPeepholeProc :: TAC.Proc -> (TAC.Proc, Bool)
tacPeepholeProc p =
  let is0 = TAC.procInstrs p
      (is1, c1) = elimGotoToNextLabel is0
      (is2, c2) = mapPureBinOpSimp is1
   in (p { TAC.procInstrs = is2 }, c1 || c2)

tacPeepholeProg :: TAC.TACProg -> (TAC.TACProg, Bool)
tacPeepholeProg prog =
  let (ps, chs) = unzip (map tacPeepholeProc (TAC.tacProcs prog))
   in (prog { TAC.tacProcs = ps }, or chs)

defaultTacPasses :: [Pass TAC.TACProg]
defaultTacPasses =
  [ Pass
      { passId = PassId "tac-peephole"
      , passDesc = "Local TAC cleanup (goto next label, algebraic binops)"
      , passDefaultOn = [Os, O1]
      , passRun = \p ->
          let (out, ch) = tacPeepholeProg p
           in PassResult out ch
      }
  , Pass
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

