-- | 48-bit RRISC float packing (reference semantics from pytools/float48.py).
module RRISC.Float48 (fromFloat) where

import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import GHC.Float (decodeFloat)

bias, sigBits, sigMask, expMax, expInf :: Int
bias = 1024
sigBits = 36
sigMask = (1 `shiftL` sigBits) - 1
expMax = 2047
expInf = expMax

wordMask :: Int
wordMask = 0xFFF

pack :: Int -> Int -> Integer -> (Int, Int, Int, Int)
pack sign expRaw sig =
  let w0 = ((sign .&. 1) `shiftL` 11) .|. (expRaw .&. 0x7FF)
      sigI = sig
      w1 = fromIntegral ((sigI `shiftR` 24) .&. 0xFFF)
      w2 = fromIntegral ((sigI `shiftR` 12) .&. 0xFFF)
      w3 = fromIntegral (sigI .&. 0xFFF)
   in (w0, w1, w2, w3)

integerBitLen :: Integer -> Int
integerBitLen 0 = 0
integerBitLen n = 1 + integerBitLen (n `shiftR` 1)

-- | Python @math.frexp@: @x = m * 2^e@ with @0.5 <= m < 1@ for finite non-zero @x@.
frexp :: Double -> (Double, Int)
frexp x
  | x < 0 =
      let (m, e) = frexp (-x)
       in (-m, e)
  | x == 0 = (0, 0)
  | Prelude.isNaN x || Prelude.isInfinite x = (0, 0)
  | otherwise =
      let (mInt, eInt) = decodeFloat x
          mAbs = abs mInt
          d = integerBitLen mAbs
          mant = fromIntegral mAbs / (2 :: Double) ^^ d
          eOut = eInt + d
       in (mant, eOut)

-- | Four 12-bit words, matching @pytools.float48.from_float@.
fromFloat :: Double -> [Int]
fromFloat x
  | Prelude.isNaN x =
      let (a, b, c, d) = pack 0 expInf (1 `shiftL` 10)
       in [a .&. wordMask, b .&. wordMask, c .&. wordMask, d .&. wordMask]
  | Prelude.isInfinite x =
      let s = if x < 0 then 1 else 0
          (a, b, c, d) = pack s expInf 0
       in [a .&. wordMask, b .&. wordMask, c .&. wordMask, d .&. wordMask]
  | x == 0 || Prelude.isNegativeZero x =
      let s = if Prelude.isNegativeZero x || x < 0 then 1 else 0
          (a, b, c, d) = pack s 0 0
       in [a .&. wordMask, b .&. wordMask, c .&. wordMask, d .&. wordMask]
  | otherwise =
      let (m, e2) = frexp x
          mAbs = abs m
          sig :: Integer
          sig = floor (mAbs * (2 ^ sigBits))
          expRaw = e2 + bias - 1
          sgn = if x < 0 then 1 else 0
          (a, b, c, d)
            | expRaw >= expInf = pack sgn expInf 0
            | expRaw <= 0 = pack sgn 0 0
            | otherwise = pack sgn expRaw (sig .&. fromIntegral sigMask)
       in [a .&. wordMask, b .&. wordMask, c .&. wordMask, d .&. wordMask]
