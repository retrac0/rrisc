{-# LANGUAGE MultiWayIf #-}
-- | Instruction decode and disassembly (pytools/isa.py).
module RRISC.Disasm (branchOffset, disasmWord) where

import Data.Bits ((.&.), shiftR)
import Data.Char (intToDigit)
import Numeric (showIntAtBase)

import RRISC.ISA (
  addOp,
  addcOp,
  addiOp,
  andOp,
  imm6Mask,
  luiOp,
  specOp,
  subOp,
  subiOp,
  jalrRb,
  lwrRb,
  rolRb,
  rorRb,
  swrRb,
  wordMask,
 )

branchOffset :: Int -> Int -> Int
branchOffset rd imm6 =
  let imm = imm6 .&. imm6Mask
   in if rd == 7 then imm - 64 else imm

padOct2 :: Int -> String
padOct2 n =
  let s = showIntAtBase 8 intToDigit n ""
   in if length s < 2 then '0' : s else s

disasmWord :: Int -> String
disasmWord w0 =
  let w = w0 .&. wordMask
      op = (w `shiftR` 9) .&. 7
      rd = (w `shiftR` 6) .&. 7
      ra = (w `shiftR` 3) .&. 7
      rb = w .&. 7
      imm = w .&. imm6Mask
      signedOff o =
        (if o >= 0 then "+" else "") ++ show o
   in if
        | w == 0o0000 -> "nop"
        | w == 0o3000 -> "clrt"
        | w == 0o7777 -> "halt"
        | op == andOp -> "and r" ++ show rd ++ ", r" ++ show ra ++ ", r" ++ show rb
        | op == subOp -> "sub r" ++ show rd ++ ", r" ++ show ra ++ ", r" ++ show rb
        | op == addOp -> "add r" ++ show rd ++ ", r" ++ show ra ++ ", r" ++ show rb
        | op == addcOp -> "addc r" ++ show rd ++ ", r" ++ show ra ++ ", r" ++ show rb
        | op == luiOp && (rd == 0 || rd == 7) -> "bf " ++ signedOff (branchOffset rd imm)
        | op == addiOp && (rd == 0 || rd == 7) -> "bt " ++ signedOff (branchOffset rd imm)
        | op == luiOp -> "lui r" ++ show rd ++ ", " ++ padOct2 imm
        | op == addiOp -> "addi r" ++ show rd ++ ", " ++ show imm
        | op == subiOp -> "subi r" ++ show rd ++ ", " ++ show imm
        | op == specOp && rb == jalrRb -> "jalr r" ++ show rd ++ ", r" ++ show ra
        | op == specOp && rb == rorRb -> "ror r" ++ show rd ++ ", r" ++ show ra
        | op == specOp && rb == rolRb -> "rol r" ++ show rd ++ ", r" ++ show ra
        | op == specOp && rb == lwrRb -> "lwr r" ++ show rd ++ ", r" ++ show ra
        | op == specOp && rb == swrRb -> "swr r" ++ show rd ++ ", r" ++ show ra
        | otherwise -> "unknown"
