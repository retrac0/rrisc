module Main where

import Control.Monad (when)
import Data.Char (isDigit)
import Data.List (intercalate)
import qualified Data.Map.Strict as Map
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
import qualified RCC.LowerSSA as LowerSSA
import qualified RCC.Codegen  as Codegen
import qualified RCC.OptFramework as OF
import qualified RCC.OptFrameworkSSA as OFSSA
import qualified RCC.Pass as Pass
import qualified RCC.Pipeline as Pipe
import qualified RCC.SSA.Prog as SSA
import qualified RCC.SSA.ToTACProg as ToTACProg
import qualified RCC.TAC as TAC
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
  , optOptLevel     :: Pipe.OptLevel
  , optPassToggles  :: Maybe String
  , optDumpAst      :: Bool
  , optDumpTac      :: Bool
  , optDumpSsa      :: Bool
  } deriving (Show)

defaultOptions :: Options
defaultOptions = Options
  { optInput        = ""
  , optOutput       = Nothing
  , optCodeBase     = 0o1000
  , optDataBase     = 0o0000
  , optStackTop     = Just 0o7770
  , optPreprocessor = Nothing
  , optOptLevel     = Pipe.Os
  , optPassToggles  = Nothing
  , optDumpAst      = False
  , optDumpTac      = False
  , optDumpSsa      = False
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
    go opts ("--dump-ssa" : rest) = go opts{ optDumpSsa = True } rest
    -- Compatibility flags (map onto -Os / -O0)
    go opts ("--no-optimize" : rest) = go opts{ optOptLevel = Pipe.O0 } rest
    go opts ("--optimize" : rest) = go opts{ optOptLevel = Pipe.Os } rest
    -- New optimization levels
    go opts ("-O0" : rest) = go opts{ optOptLevel = Pipe.O0 } rest
    go opts ("-Os" : rest) = go opts{ optOptLevel = Pipe.Os } rest
    go opts ("-O1" : rest) = go opts{ optOptLevel = Pipe.O1 } rest
    go opts ("-O2" : rest) = go opts{ optOptLevel = Pipe.O1 } rest
    -- Per-pass overrides
    go opts ("--pass" : spec : rest) = go opts{ optPassToggles = Just spec } rest
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
    , "  -O0                   no SSA opts (plain CFG lowering)"
    , "  -Os                   optimize for size (default)"
    , "  -O1                   optimize for speed"
    , "  -O2                   (compat) same as -O1"
    , "  --pass +id,-id,...    enable/disable specific passes"
    , "  --optimize            (compat) same as -Os"
    , "  --no-optimize         (compat) same as -O0"
    , "  --dump-ast            print lexical AST and exit"
    , "  --dump-tac            print TAC and exit"
    , "  --dump-ssa            print SSA (debug) and exit"
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

  let ssa :: SSA.SSAProg
      ssa =
        case optOptLevel opts of
          Pipe.O0 -> LowerSSA.lowerSSAPlain checked
          _       -> LowerSSA.lowerSSA checked

  when (optDumpSsa opts) $ print ssa >> exitSuccess

  -- SSA-stage optimization pipeline (skipped entirely at -O0).
  ssa' <- case optOptLevel opts of
    Pipe.O0 -> pure ssa
    _ -> do
      let ssaPipe = Pipe.defaultPipeline (optOptLevel opts) OFSSA.defaultSsaPasses
          ssaBaseEnabled = Pipe.pipelineEnabledMap ssaPipe
      ssaEnabled <- case optPassToggles opts of
        Nothing -> pure ssaBaseEnabled
        Just s  ->
          case Pass.parsePassToggles s of
            Left e -> die ("--pass: " <> e)
            Right m -> pure (m `Map.union` ssaBaseEnabled)
      pure (OFSSA.optimizeSSAWith ssaEnabled (Pipe.plPasses ssaPipe) ssa)

  let tac :: TAC.TACProg
      tac = ToTACProg.toTACProg ssa'

  let pipe0 = Pipe.defaultPipeline (optOptLevel opts) OF.defaultTacPasses
  let baseEnabled = Pipe.pipelineEnabledMap pipe0
  passEnabled <- case optPassToggles opts of
    Nothing -> pure baseEnabled
    Just s  ->
      case Pass.parsePassToggles s of
        Left e -> die ("--pass: " <> e)
        Right m -> pure (m `Map.union` baseEnabled)
  let tac' = OF.optimizeWith passEnabled (Pipe.plPasses pipe0) tac

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
