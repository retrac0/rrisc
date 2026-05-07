module RRISC.ISA (
  andOp, subOp, addOp, addiOp, addcOp, luiOp, subiOp, specOp,
  jalrRb, rorRb, rolRb, lwrRb, swrRb,
  encodeR3, encodeRI, wordMask, imm6Mask,
) where

import Data.Bits ((.&.), (.|.), shiftL)

andOp, subOp, addOp, addcOp, luiOp, addiOp, subiOp, specOp :: Int
andOp = 0
subOp = 1
addOp = 2
addcOp = 3
luiOp = 4
addiOp = 5
subiOp = 6
specOp = 7

jalrRb, rorRb, rolRb, lwrRb, swrRb :: Int
jalrRb = 0
rorRb = 1
rolRb = 2
lwrRb = 3
swrRb = 4

wordMask, imm6Mask :: Int
wordMask = 0o7777
imm6Mask = 0o77

encodeR3 :: Int -> Int -> Int -> Int -> Int
encodeR3 op rd ra rb =
  ((op .&. 7) `shiftL` 9) .|. ((rd .&. 7) `shiftL` 6) .|. ((ra .&. 7) `shiftL` 3) .|. (rb .&. 7)

encodeRI :: Int -> Int -> Int -> Int
encodeRI op rd imm6 =
  ((op .&. 7) `shiftL` 9) .|. ((rd .&. 7) `shiftL` 6) .|. (imm6 .&. imm6Mask)
