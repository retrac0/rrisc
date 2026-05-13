module RCC.Ir.SSA.ToTACProg
  ( toTACProg
  ) where

import qualified RCC.Ir.SSA.Prog as SP
import qualified RCC.Ir.SSA.ToTAC as ToTAC
import qualified RCC.Ir.TAC as TAC

toTACProg :: SP.SSAProg -> TAC.TACProg
toTACProg p =
  TAC.TACProg
    (SP.ssaGlobals p)
    [ ToTAC.fromSSA (SP.spLocSzs sp) (SP.spFunc sp)
    | sp <- SP.ssaProcs p
    ]

