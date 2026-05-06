module Main where

import Control.Monad (when)
import qualified Data.Text.IO as TIO
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)

import qualified RCC.Parser   as Parser
import qualified RCC.Sema     as Sema
import qualified RCC.TAC      as TAC
import qualified RCC.Optimize as Opt
import qualified RCC.Codegen  as Codegen
import RCC.Error (Diagnostic, formatDiagnostic)

-- ---------------------------------------------------------------------------
-- CLI options

data Options = Options
  { optInput    :: FilePath
  , optOutput   :: Maybe FilePath
  , optCodeBase :: Int
  , optDataBase :: Int
  , optStackTop :: Maybe Int
  , optDumpAst  :: Bool
  , optDumpTac  :: Bool
  } deriving (Show)

defaultOptions :: Options
defaultOptions = Options
  { optInput    = ""
  , optOutput   = Nothing
  , optCodeBase = 0o1000
  , optDataBase = 0o0000   -- zero-page RAM in default sim
  , optStackTop = Just 0o0100   -- top of zero-page RAM
  , optDumpAst  = False
  , optDumpTac  = False
  }

parseArgs :: [String] -> Either String Options
parseArgs = go defaultOptions
  where
    go opts [] =
      if null (optInput opts)
        then Left "no input file specified"
        else Right opts
    go opts ("-o"           : f : rest) = go opts{ optOutput   = Just f }       rest
    go opts ("--code-base"  : a : rest) = go opts{ optCodeBase = read a }        rest
    go opts ("--data-base"  : a : rest) = go opts{ optDataBase = read a }        rest
    go opts ("--stack-top"  : a : rest) = go opts{ optStackTop = Just (read a) } rest
    go opts ("--dump-ast"       : rest) = go opts{ optDumpAst  = True }          rest
    go opts ("--dump-tac"       : rest) = go opts{ optDumpTac  = True }          rest
    go _    (('-' : flag)       : _   ) = Left ("unknown flag: -" <> flag)
    go opts (f              :     rest) = go opts{ optInput = f }                 rest

usage :: String -> String
usage prog = unlines
  [ "Usage: " <> prog <> " [options] <input.c>"
  , "  -o <file>          output file (default: stdout)"
  , "  --code-base <n>    code section base address (default: 0o1000)"
  , "  --data-base <n>    data section base address (default: 0o3000)"
  , "  --stack-top <n>    initial stack pointer     (default: data-base)"
  , "  --dump-ast         print lexical AST and exit"
  , "  --dump-tac         print TAC and exit"
  ]

-- ---------------------------------------------------------------------------
-- Entry point

main :: IO ()
main = do
  prog <- getProgName
  args <- getArgs
  opts <- case parseArgs args of
    Left err -> die (err <> "\n" <> usage prog)
    Right o  -> return o

  src <- TIO.readFile (optInput opts)

  -- Stage 1: Parse
  ast <- case Parser.parseProgram (optInput opts) src of
    Left  d -> dieDiag d
    Right p -> return p

  when (optDumpAst opts) $ print ast >> exitSuccess

  -- Stage 2: Semantic analysis
  checked <- case Sema.check ast of
    Left  d -> dieDiag d
    Right p -> return p

  -- Stage 3: TAC lowering
  let tac = TAC.lower checked

  -- Stage 4: Optimize
  let tac' = Opt.optimize tac

  when (optDumpTac opts) $ print tac' >> exitSuccess

  -- Stage 5: Codegen
  let cgopts = Codegen.CodegenOpts
        { Codegen.codeBase = optCodeBase opts
        , Codegen.dataBase = optDataBase opts
        , Codegen.stackTop = maybe (optDataBase opts) id (optStackTop opts)
        }
  let asm = Codegen.codegen cgopts tac'

  -- Write output
  case optOutput opts of
    Nothing -> TIO.putStr asm
    Just fp -> TIO.writeFile fp asm

-- ---------------------------------------------------------------------------
-- Helpers

die :: String -> IO a
die msg = hPutStrLn stderr msg >> exitFailure

dieDiag :: Diagnostic -> IO a
dieDiag d = TIO.hPutStrLn stderr (formatDiagnostic d) >> exitFailure
