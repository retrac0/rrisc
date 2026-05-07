module Main (main) where

import Control.Concurrent (yield)
import Control.Exception (catch, finally)
import Control.Monad (when)
import qualified Data.ByteString.Char8 as B8
import Data.Bits ((.&.))
import Data.IORef (modifyIORef', readIORef)
import Options.Applicative (
  Parser,
  ParserInfo,
  argument,
  auto,
  execParser,
  fullDesc,
  help,
  header,
  helper,
  info,
  long,
  many,
  metavar,
  option,
  optional,
  progDesc,
  str,
  strOption,
  switch,
  value,
  (<**>),
 )
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)

import RRISC.ISA (wordMask)
import RRISC.Sim.Bus (setBusTrace)
import RRISC.Sim.CPU (
  CPU (..),
  CpuScalars (..),
  MaxCycleErr (..),
  loadMem,
  newCPU,
  randomizeCPU,
  showState,
  stepCPU,
 )
import RRISC.Sim.Memory (parseMemSpec)
import RRISC.Sim.Terminal (TerminalOptions (..), attachTerminal)

data Opts = Opts
  { optTrace :: !Bool
  , optBusTrace :: !Bool
  , optSummary :: !Bool
  , optRandomize :: !Bool
  , optTerminal :: !Bool
  , optUartPreload :: !(Maybe String)
  , optTranslate :: !Bool
  , optStart :: !String
  , optMaxCycle :: !Int
  , optMem :: ![String]
  , optBinary :: !FilePath
  }

optsP :: Parser Opts
optsP =
  Opts
    <$> switch (long "trace" <> help "enable instruction trace output")
    <*> switch (long "bustrace" <> help "trace all memory bus reads and writes")
    <*> switch (long "summary" <> help "print final machine state and instruction count")
    <*> switch (long "randomize" <> help "randomize registers and RAM before loading program")
    <*> switch (long "terminal" <> help "attach UART terminal device")
    <*> optional (strOption (long "uart-preload" <> metavar "STR" <> help "UTF-8 string for RX FIFO before run (disables stdin reader)"))
    <*> switch (long "translate" <> help "SIXBIT translation on the terminal (default: raw bytes)")
    <*> strOption (long "start" <> metavar "ADDR" <> value "0" <> help "start address in octal (default 0, interpreted as octal like Python int(s, 8))")
    <*> option auto (long "maxcycle" <> metavar "N" <> value 0 <> help "halt with error after N cycles")
    <*> many (strOption (long "mem" <> metavar "TYPE:BASE:SIZE" <> help "memory bank (repeatable)"))
    <*> argument str (metavar "BINARY")

optsInfo :: ParserInfo Opts
optsInfo =
  info (optsP <**> helper) $
    fullDesc
      <> progDesc "RRISC simulator (sim.py parity)"
      <> header "rsim — RRISC simulator"

-- | Match @int(args.start, 8)@ in sim.py (always octal base 8).
readStartOct :: String -> Int
readStartOct s0 =
  let s = dropWhile (== ' ') . reverse . dropWhile (== ' ') . reverse $ s0
   in case s of
        '0' : 'o' : r | not (null r) -> read ("0o" ++ r) .&. wordMask
        _ -> read ("0o" ++ s) .&. wordMask

main :: IO ()
main = do
  o <- execParser optsInfo
  let specs = map parseMemSpec (optMem o)
  -- Fast RAM bypasses per-access bus logging; keep full bus when --bustrace is on.
  cpu <- newCPU specs (not (optBusTrace o))
  modifyIORef' (cScalars cpu) $ \s ->
    s
      { csTrace = optTrace o
      , csMaxCycles = optMaxCycle o
      }
  setBusTrace (cBus cpu) (optBusTrace o)

  termCleanup <-
    if optTerminal o
      then do
        let readStdin = optUartPreload o == Nothing
            pre = B8.pack <$> optUartPreload o
        attachTerminal (cBus cpu) (TerminalOptions (optTranslate o) pre readStdin)
      else pure (pure ())

  let body = do
        when (optRandomize o) $ randomizeCPU cpu
        loadMem cpu (optBinary o)
        modifyIORef' (cScalars cpu) $ \s ->
          s
            { csPc = readStartOct (optStart o)
            , csUartYield = optTerminal o && optUartPreload o == Nothing
            }

        let runLoop = do
              running <- csRunning <$> readIORef (cScalars cpu)
              when running $ do
                stepCPU cpu
                uy <- csUartYield <$> readIORef (cScalars cpu)
                ir <- csInstrRetired <$> readIORef (cScalars cpu)
                when (uy && (ir .&. 0x3F == 0)) yield
                runLoop

        runLoop
        tr <- csTrace <$> readIORef (cScalars cpu)
        when (tr || optSummary o) $ showState cpu >>= putStr
        exitSuccess

  flip finally termCleanup $
    body `catch` \(MaxCycleErr n) -> do
      hPutStrLn stderr $ "maxcycle " ++ show n ++ " reached"
      exitFailure
