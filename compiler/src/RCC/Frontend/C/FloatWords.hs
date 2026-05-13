-- | Float literal encoding for the C frontend (float48 for the RRISC rcc port).
module RCC.Frontend.C.FloatWords
  ( encodeFloatLiteralWords
  ) where

import Data.Bits ((.&.), (.|.), shiftL, shiftR)

import RCC.Ir.DataLayout (DataLayout (..))

-- | Encode a C double literal as @dlFloatWords@ data words (float48 when @dlFloatWords == 4@).
encodeFloatLiteralWords :: DataLayout -> Double -> [Int]
encodeFloatLiteralWords dl x
  | dlFloatWords dl /= 4 =
      error "RCC.Frontend.C.FloatWords.encodeFloatLiteralWords: only 4-word float literals supported"
  | isNaN x      = [0x7FF, 0, 0x400, 0]
  | isInfinite x = if x > 0 then [0x7FF, 0, 0, 0] else [0xFFF, 0, 0, 0]
  | x == 0.0     = [0, 0, 0, 0]
  | otherwise    =
      let sign      = if x < 0 then 1 else 0
          (m, n)    = decodeFloat (abs x)
          sig48     = fromInteger m `shiftR` 17 :: Int
          exp48     = n + 1076
          w0        = (sign `shiftL` 11) .|. (exp48 .&. 0x7FF)
          w1        = (sig48 `shiftR` 24) .&. 0xFFF
          w2        = (sig48 `shiftR` 12) .&. 0xFFF
          w3        = sig48 .&. 0xFFF
      in if exp48 >= 0x7FF
           then [(sign `shiftL` 11) .|. 0x7FF, 0, 0, 0]
           else if exp48 <= 0
                  then [0, 0, 0, 0]
                  else [w0, w1, w2, w3]
