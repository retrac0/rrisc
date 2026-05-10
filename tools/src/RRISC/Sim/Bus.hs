{-# LANGUAGE BangPatterns #-}

-- | Memory bus (sim.py @Bus@).
module RRISC.Sim.Bus (
  Bus,
  BusHandler (..),
  BusConflict (..),
  newBus,
  registerAddress,
  registerRange,
  busRead,
  busWrite,
  busTrace,
  setBusTrace,
 ) where

import Data.Bits ((.&.))
import Control.Exception (Exception, throwIO)
import Control.Monad (when)
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef, writeIORef)
import qualified Data.Vector as V
import Data.Vector ((//), (!))
import Text.Printf (printf)

import RRISC.ISA (wordMask)

addrMask :: Int
addrMask = wordMask

data BusHandler = BusHandler
  { bhRead :: !(Maybe (Int -> IO (Maybe Int)))
  , bhWrite :: !(Maybe (Int -> Int -> IO ()))
  }

data BusConflict = BusConflict
  { bcAddr :: !Int
  , bcVals :: ![Int]
  }
  deriving (Show)

instance Exception BusConflict

data Bus = Bus
  { busHandlers :: !(IORef (V.Vector [BusHandler]))
  , busTraceRef :: !(IORef Bool)
  }

newBus :: IO Bus
newBus =
  Bus
    <$> newIORef (V.replicate (addrMask + 1) [])
    <*> newIORef False

busTrace :: Bus -> IO Bool
busTrace = readIORef . busTraceRef

setBusTrace :: Bus -> Bool -> IO ()
setBusTrace b x = writeIORef (busTraceRef b) x

registerAddress :: Bus -> Int -> BusHandler -> IO ()
registerAddress bus addr h =
  registerRange bus addr (addr + 1) h

registerRange :: Bus -> Int -> Int -> BusHandler -> IO ()
registerRange bus start0 end0 h = do
  let !start = start0 .&. addrMask
      !end = end0
  atomicModifyIORef' (busHandlers bus) $ \v ->
    let go !i acc
          | i >= end = acc
          | otherwise =
              let a = i .&. addrMask
               in go (i + 1) (acc // [(a, (acc ! a) ++ [h])])
     in (go start v, ())

busRead :: Bus -> Int -> IO Int
busRead bus addr0 = do
  let addr = addr0 .&. addrMask
  v <- readIORef (busHandlers bus)
  let hs = v ! addr
      readHandlers = [r | BusHandler (Just r) _ <- hs]
  mvs <- mapM (\r -> r addr) readHandlers
  let responses = [x .&. addrMask | Just x <- mvs]
  tr <- readIORef (busTraceRef bus)
  case responses of
    [] -> do
      let result = 0o7777
      when tr $
        putStrLn $
          printf "  bus rd %04o -> %04o [float]" addr result
      pure result
    [x] -> do
      let r = x .&. addrMask
      when tr $ do
        let note = if length hs > 1 then printf " [%d drivers]" (length hs) else ""
        putStrLn $ printf ("  bus rd %04o -> %04o" ++ note) addr r
      pure r
    xs ->
      throwIO (BusConflict addr (map (.&. addrMask) xs))

busWrite :: Bus -> Int -> Int -> IO ()
busWrite bus addr0 val0 = do
  let addr = addr0 .&. addrMask
      val = val0 .&. addrMask
  v <- readIORef (busHandlers bus)
  let hs = v ! addr
      writers = [w | BusHandler _ (Just w) <- hs]
  mapM_ (\w -> w addr val) writers
  tr <- readIORef (busTraceRef bus)
  when tr $ do
    let note = if length writers /= 1 then printf " [%d writers]" (length writers) else ""
    putStrLn $ printf ("  bus wr %04o <- %04o" ++ note) addr val
