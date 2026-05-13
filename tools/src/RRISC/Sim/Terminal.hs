{-# LANGUAGE BangPatterns #-}

-- | UART terminal (pytools/terminal.py parity).
module RRISC.Sim.Terminal (
  TerminalOptions (..),
  attachTerminal,
) where

import Control.Concurrent (ThreadId, forkIO, killThread)
import Control.Concurrent.STM (
  atomically,
  modifyTVar',
  newTVarIO,
  readTVar,
  writeTVar,
 )
import Control.Exception (catch, throwIO)
import Control.Monad (when)
import Data.Bits ((.&.))
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import qualified Data.ByteString as B
import Data.Char (chr, ord)
import qualified Data.Sequence as Seq
import GHC.IO.Exception (IOErrorType (EOF, ResourceVanished), IOException, ioe_type)
import System.IO (
  BufferMode (..),
  hGetChar,
  hIsTerminalDevice,
  hSetBinaryMode,
  hSetBuffering,
  hSetEcho,
  hFlush,
  stdin,
  stdout,
 )

import RRISC.SixBit (decodeSixbit, encodeSixbit)
import RRISC.Sim.Bus (Bus, BusHandler (..), registerAddress)

rxDepth :: Int
rxDepth = 16

type RxFifo = Seq.Seq Int

data TerminalOptions = TerminalOptions
  { termTranslate :: !Bool
  , termPreload :: !(Maybe B.ByteString)
  , termReadStdin :: !Bool
  }

isEOFish :: IOException -> Bool
isEOFish e =
  case ioe_type e of
    EOF -> True
    ResourceVanished -> True
    _ -> False

pushRx :: RxFifo -> Int -> RxFifo
pushRx s v =
  if Seq.length s >= rxDepth
    then s -- drop new (queue.Full in Python)
    else s Seq.|> v

popRx :: RxFifo -> (Maybe Int, RxFifo)
popRx s =
  case Seq.viewl s of
    Seq.EmptyL -> (Nothing, s)
    v Seq.:< rest -> (Just v, rest)

-- | Register UART at @0o7770@–@0o7773@. Returns an action to restore stdin buffering.
--
-- When @termReadStdin@ is true we spawn a reader thread (same role as Python's daemon
-- @terminal-rx@). It often blocks in @hGetChar@; we @killThread@ on shutdown so @rrsim@
-- exits after the CPU halts instead of waiting for interactive input.
attachTerminal :: Bus -> TerminalOptions -> IO (IO ())
attachTerminal bus opts = do
  rx <- newTVarIO (Seq.empty :: RxFifo)
  readerTid :: IORef (Maybe ThreadId) <- newIORef Nothing
  case termPreload opts of
    Just bs ->
      atomically $
        modifyTVar' rx $ \s0 ->
          foldl (\acc b -> pushRx acc (fromIntegral b .&. 0xFF)) s0 (B.unpack bs)
    Nothing -> pure ()

  -- Match pytools/terminal.py: unbuffered byte reads for the RX thread.  Without this,
  -- @hGetChar@ on a non-'hIsTerminalDevice' Handle stays line-buffered and
  -- interactive @getchar()@ in the guest never sees keys until Enter.
  termStdin <- hIsTerminalDevice stdin
  -- Guest UART programs (e.g. RPN) echo input; suppress kernel echo on real TTYs.
  let guestEchoesInput = termReadStdin opts && termStdin

  when (termReadStdin opts) $ do
    hSetBinaryMode stdin True
    hSetBuffering stdin NoBuffering

  when guestEchoesInput $ hSetEcho stdin False

  -- Match pytools/terminal.py: stop the reader thread on stdin EOF (pipe/file closed), do not spin forever.
  when (termReadStdin opts) $ do
    tid <-
      forkIO $
        let go =
              do
                ch <- hGetChar stdin
                if termTranslate opts
                  then case encodeSixbit ch of
                    Nothing -> pure ()
                    Just v -> atomically $ modifyTVar' rx (`pushRx` v)
                  else atomically $ modifyTVar' rx (`pushRx` ((fromIntegral (ord ch) :: Int) .&. 0xFF))
                go
         in go
              `catch` ( \e ->
                        if isEOFish (e :: IOException)
                          then pure ()
                          else throwIO e
                      )
    writeIORef readerTid (Just tid)

  let txReady _ = pure (Just 1)
      rxReady _ = atomically $ do
        s <- readTVar rx
        pure (Just (if Seq.null s then 0 else 1))
      txWrite _ val =
        if termTranslate opts
          then case decodeSixbit (fromIntegral val .&. 0x3F) of
            "" -> pure ()
            str -> putStr str >> hFlush stdout
          else do
            putChar (chr (fromIntegral val .&. 0xFF))
            hFlush stdout
      rxRead _ = atomically $ do
        s0 <- readTVar rx
        case popRx s0 of
          (Nothing, _) -> pure (Just 0)
          (Just v, s1) -> writeTVar rx s1 >> pure (Just v)

  registerAddress bus 0o7770 (BusHandler (Just txReady) Nothing)
  registerAddress bus 0o7771 (BusHandler (Just rxReady) Nothing)
  registerAddress bus 0o7772 (BusHandler Nothing (Just txWrite))
  registerAddress bus 0o7773 (BusHandler (Just rxRead) Nothing)

  pure $ do
    readIORef readerTid >>= mapM_ killThread
    when guestEchoesInput $ hSetEcho stdin True
    when (termReadStdin opts) $ do
      hSetBuffering stdin LineBuffering
      hSetBinaryMode stdin False
