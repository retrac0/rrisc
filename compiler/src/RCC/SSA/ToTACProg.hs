module RCC.SSA.ToTACProg
  ( toTACProg
  ) where

import qualified RCC.SSA.Prog as SP
import qualified RCC.SSA.ToTAC as ToTAC
import qualified RCC.TAC as TAC

toTACProg :: SP.SSAProg -> TAC.TACProg
toTACProg p =
  TAC.TACProg
    (SP.ssaGlobals p)
    [ ToTAC.fromSSA (SP.spLocSzs sp) (SP.spFunc sp)
    | sp <- SP.ssaProcs p
    ]

