module Main where

import Control.Monad (when)
import Data.Char (isDigit)
import Data.List (intercalate)
import Data.Version (showVersion)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)
import System.Process (readProcess)

import Paths_rcc (version)

import RCC.CliParse (parseIntArg)
import qualified RCC.Parser   as Parser
import qualified RCC.Sema     as Sema
import qualified RCC.Lower    as Lower
import qualified RCC.Optimize as Opt
import qualified RCC.Codegen  as Codegen
import RCC.Error (Diagnostic, formatDiagnostic)

-- ---------------------------------------------------------------------------
-- CLI options

data Options = Options
  { optInput        :: FilePath
  , optOutput       :: Maybe FilePath
  , optCodeBase     :: Int
  , optDataBase     :: Int
  , optStackTop     :: Maybe Int
  , optPreprocessor :: Maybe String
  , optOptimize     :: Bool
  , optDumpAst      :: Bool
  , optDumpTac      :: Bool
  } deriving (Show)

defaultOptions :: Options
defaultOptions = Options
  { optInput        = ""
  , optOutput       = Nothing
  , optCodeBase     = 0o1000
  , optDataBase     = 0o0000
  , optStackTop     = Just 0o7770
  , optPreprocessor = Nothing
  , optOptimize     = True
  , optDumpAst      = False
  , optDumpTac      = False
  }

parseArgs :: [String] -> Either String Options
parseArgs = go defaultOptions
  where
    go opts [] =
      if null (optInput opts)
        then Left "no input file specified"
        else Right opts
    go opts ("-o" : f : rest) = go opts{ optOutput = Just f } rest
    go opts ("--code-base" : a : rest) =
      either (\e -> Left ("--code-base: " <> e)) (\n -> go opts{ optCodeBase = n } rest) (parseIntArg a)
    go opts ("--data-base" : a : rest) =
      either (\e -> Left ("--data-base: " <> e)) (\n -> go opts{ optDataBase = n } rest) (parseIntArg a)
    go opts ("--stack-top" : a : rest) =
      either (\e -> Left ("--stack-top: " <> e)) (\n -> go opts{ optStackTop = Just n } rest) (parseIntArg a)
    go opts ("--preprocessor" : c : rest) = go opts{ optPreprocessor = Just c } rest
    go opts ("--dump-ast" : rest) = go opts{ optDumpAst = True } rest
    go opts ("--dump-tac" : rest) = go opts{ optDumpTac = True } rest
    go opts ("--no-optimize" : rest) = go opts{ optOptimize = False } rest
    go opts ("--optimize" : rest) = go opts{ optOptimize = True } rest
    go _ (('-' : '-' : _) : _) = Left "unknown option (try --help)"
    go _ (('-' : _) : _) = Left "unknown flag"
    go opts (f : rest) = go opts{ optInput = f } rest

usage :: String -> String
usage prog =
  intercalate
    "\n"
    [ "Usage: " <> prog <> " [options] <input.c>"
    , "  -o <file>             output file (default: stdout)"
    , "  --code-base <n>       code section base when no RW globals (default: 0o1000)"
    , "  --data-base <n>       RW globals base address (default: 0o0000)"
    , "  --stack-top <n>       initial stack pointer     (default: 0o7770)"
    , "  --preprocessor <cmd>  run <cmd> on source before compiling (e.g. 'cpp -P')"
    , "  --optimize            enable TAC optimizations (default; omit with --no-optimize)"
    , "  --no-optimize         skip TAC optimizations (debug only; large programs may not assemble)"
    , "  --dump-ast            print lexical AST and exit"
    , "  --dump-tac            print TAC and exit"
    , "  -V, --version         print version and exit"
    ]

-- ---------------------------------------------------------------------------
-- Preprocessor

-- Run cmd on inputFile, strip GCC/Clang linemarkers, return processed source.
runPreprocessor :: String -> FilePath -> IO T.Text
runPreprocessor cmd inputFile =
  case words cmd of
    []           -> die "empty --preprocessor command"
    (exe : rest) -> do
      out <- readProcess exe (rest ++ [inputFile]) ""
      pure $ T.unlines $ filter (not . isLinemarker) $ T.lines (T.pack out)
  where
    isLinemarker line = case T.uncons line of
      Just ('#', t) -> case T.uncons (T.dropWhile (== ' ') t) of
        Just (c, _) -> isDigit c
        Nothing     -> False
      _ -> False

-- ---------------------------------------------------------------------------
-- Entry point

main :: IO ()
main = do
  prog <- getProgName
  args <- getArgs
  when (args == ["--version"] || args == ["-V"]) $ do
    putStrLn ("rcc " <> showVersion version)
    exitSuccess
  opts <- case parseArgs args of
    Left err -> die (err <> "\n" <> usage prog)
    Right o  -> return o

  src <- case optPreprocessor opts of
    Nothing  -> TIO.readFile (optInput opts)
    Just cmd -> runPreprocessor cmd (optInput opts)

  ast <- case Parser.parseProgram (optInput opts) src of
    Left  d -> dieDiag d
    Right p -> return p

  when (optDumpAst opts) $ print ast >> exitSuccess

  checked <- case Sema.check ast of
    Left  d -> dieDiag d
    Right p -> return p

  let tac  = Lower.lower checked
  let tac' = Opt.optimizeWhen (optOptimize opts) tac

  when (optDumpTac opts) $ print tac' >> exitSuccess

  let cgopts = Codegen.CodegenOpts
        { Codegen.codeBase = optCodeBase opts
        , Codegen.dataBase = optDataBase opts
        , Codegen.stackTop = maybe (optDataBase opts) id (optStackTop opts)
        }
  let asm = Codegen.codegen cgopts tac'

  case optOutput opts of
    Nothing -> TIO.putStr asm
    Just fp -> TIO.writeFile fp asm

-- ---------------------------------------------------------------------------
-- Helpers

die :: String -> IO a
die msg = hPutStrLn stderr msg >> exitFailure

dieDiag :: Diagnostic -> IO a
dieDiag d = TIO.hPutStrLn stderr (formatDiagnostic d) >> exitFailure
