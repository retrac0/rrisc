-- | RRISC SIXBIT encoding (sixbit.py).
module RRISC.SixBit (encodeSixbit, decodeSixbit) where

import Data.Bits ((.&.))
import Data.Char (chr, ord)
import qualified Data.Map.Strict as M

sixbitDecode :: Int -> String
sixbitDecode 0 = ""
sixbitDecode v
  | v >= 1 && v <= 30 = [chr (v + 0x40)]
  | v == 0o37 = "\n"
  | v >= 0o40 && v <= 0o77 = [chr v]
  | otherwise = ""

table :: M.Map Char Int
table =
  let dec = [sixbitDecode v | v <- [0 .. 63]]
      pairs =
        [ (head ch, ix)
        | (ix, ch) <- zip [0 :: Int ..] dec
        , not (null ch)
        ]
      lowerFold =
        [ (toEnum (ord u + 32), enc)
        | (u, enc) <- pairs
        , u >= 'A' && u <= 'Z'
        ]
   in M.fromList (pairs ++ lowerFold ++ [('\r', 0o37)])

encodeSixbit :: Char -> Maybe Int
encodeSixbit c = M.lookup c table

-- | Decode a 6-bit SIXBIT value to a string (empty for NUL), matching @decode_sixbit@ in sixbit.py.
decodeSixbit :: Int -> String
decodeSixbit v = sixbitDecode (v .&. 0x3F)
