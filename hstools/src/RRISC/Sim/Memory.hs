{-# LANGUAGE BangPatterns #-}

-- | Memory banks and binary load (sim.py @MemBank@, @build_bus_from_banks@, @load_mem@).
module RRISC.Sim.Memory (
  BankKind (..),
  BankRecord (..),
  defaultBankSpecs,
  parseMemSpec,
  memorySystemFromSpecs,
  loadPackedBinaryIntoBanks,
) where

import Data.Bits ((.&.), (.|.), shiftL)
import Data.Char (isSpace, toLower)
import qualified Data.ByteString as B
import Data.Word (Word16)
import qualified Data.Vector.Mutable as MV
import System.IO (IOMode (..), withBinaryFile)

import RRISC.ISA (wordMask)
import RRISC.Sim.Bus (Bus, BusHandler (..), registerRange)

data BankKind = BankRam | BankRom | BankIo
  deriving (Eq, Show)

data BankRecord = BankRecord
  { brKind :: !BankKind
  , brBase :: !Int
  , brSize :: !Int
  , brVec :: !(Maybe (MV.IOVector Word16))
  }

trimSpec :: String -> String
trimSpec = reverse . dropWhile isSpace . reverse . dropWhile isSpace

defaultBankSpecs :: [(BankKind, Int, Int)]
defaultBankSpecs = [(BankRam, 0o0000, 0o7770)]

parseMemSpec :: String -> (BankKind, Int, Int)
parseMemSpec spec =
  case break (== ':') spec of
    (t, ':' : rest1) ->
      case break (== ':') rest1 of
        (b, ':' : rest2) ->
          let kind = case map toLower (trimSpec t) of
                "ram" -> BankRam
                "rom" -> BankRom
                "io" -> BankIo
                k -> error $ "unknown bank type: " ++ show k
           in (kind, readIntAuto b, readIntAuto rest2)
        _ -> bad
    _ -> bad
 where
  bad = error $ "--mem requires TYPE:BASE:SIZE, got: " ++ show spec

-- | Match Python @int(s, 0)@ for typical RRISC specs (decimal, @0o@ octal, @0x@ hex, @0b@ binary).
readIntAuto :: String -> Int
readIntAuto s0 =
  let s = trimSpec s0
   in if null s
        then error "empty integer in --mem"
        else case s of
          '0' : 'o' : r | not (null r) -> read ("0o" ++ r)
          '0' : 'O' : r | not (null r) -> read ("0o" ++ r)
          '0' : 'x' : _ -> read s
          '0' : 'X' : _ -> read s
          '0' : 'b' : _ -> read s
          '0' : 'B' : _ -> read s
          _ -> read s

memorySystemFromSpecs :: Bus -> [(BankKind, Int, Int)] -> IO [BankRecord]
memorySystemFromSpecs bus = go []
 where
  go acc [] = pure (reverse acc)
  go acc ((kind, base, size) : rest) = do
    let !baseM = base .&. wordMask
    rec <- case kind of
      BankRam -> do
        vec <- MV.new size
        MV.set vec 0
        let rd addr =
              let off = addr - baseM
               in do
                    w <- MV.read vec off
                    pure (Just (fromIntegral w))
            wr addr val =
              let off = addr - baseM
               in MV.write vec off (fromIntegral (val .&. wordMask))
        registerRange bus baseM (baseM + size) (BusHandler (Just rd) (Just wr))
        pure (BankRecord BankRam baseM size (Just vec))
      BankRom -> do
        vec <- MV.new size
        MV.set vec 0
        let rd addr =
              let off = addr - baseM
               in do
                    w <- MV.read vec off
                    pure (Just (fromIntegral w))
        registerRange bus baseM (baseM + size) (BusHandler (Just rd) Nothing)
        pure (BankRecord BankRom baseM size (Just vec))
      BankIo -> do
        let rd _ = pure (Just 0)
            wr _ _ = pure ()
        registerRange bus baseM (baseM + size) (BusHandler (Just rd) (Just wr))
        pure (BankRecord BankIo baseM size Nothing)
    go (rec : acc) rest

-- | Load packed 12-bit little-endian words into backing RAM/ROM (sim.py @load_mem@).
loadPackedBinaryIntoBanks :: FilePath -> Int -> [BankRecord] -> IO ()
loadPackedBinaryIntoBanks path addr0 banks =
  withBinaryFile path ReadMode $ \h -> loadLoop h 0
 where
  loadLoop h !i = do
    chunk <- B.hGet h 2
    if B.null chunk
      then pure ()
      else do
        let bs = if B.length chunk == 1 then chunk `B.append` B.singleton 0 else chunk
            b0 = fromIntegral (B.index bs 0) :: Int
            b1 = fromIntegral (B.index bs 1) :: Int
            word = (b0 .|. ((b1 .&. 0x0F) `shiftL` 8)) .&. wordMask
            target = (addr0 + i) .&. wordMask
        writeFirstBank target word banks
        loadLoop h (i + 1)

writeFirstBank :: Int -> Int -> [BankRecord] -> IO ()
writeFirstBank _ _ [] = pure ()
writeFirstBank addr word (br : rs) =
  case brVec br of
    Just vec
      | brBase br <= addr && addr < brBase br + brSize br ->
          MV.write vec (addr - brBase br) (fromIntegral word)
    _ -> writeFirstBank addr word rs
