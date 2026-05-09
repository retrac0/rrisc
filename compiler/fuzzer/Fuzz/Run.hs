-- | Subprocess harness for the rcc fuzzer: build a generated program with
-- both 'rcc' (+ assembler + linker + simulator) and host 'gcc -DRRISC_IO_TEST_HOST',
-- then diff the two stdouts.
--
-- The pipeline is expressed as a flat list of named 'Stage's so it's easy
-- to read, easy to extend (add a stage by adding a list element), and
-- easy to short-circuit (the runner stops at the first 'Left').
module Fuzz.Run
  ( ToolPaths (..)
  , RunOutcome (..)
  , StageError (..)
  , defaultToolPaths
  , runCase
  , runCaseFromAst
  , caseBaseName
  , runProcAllowFailure
  ) where

import Control.Exception (SomeException, try)
import qualified Data.Text.IO as TIO
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import qualified System.IO as IO
import System.Process
  ( CreateProcess (..)
  , StdStream (..)
  , createProcess
  , proc
  , waitForProcess
  )

import Fuzz.AST    (Program)
import Fuzz.Print  (Target (..), renderProgram)

-- ---------------------------------------------------------------------------
-- Paths

data ToolPaths = ToolPaths
  { tpRcc  :: !FilePath
  , tpRas  :: !FilePath
  , tpHsld :: !FilePath
  , tpRsim :: !FilePath
  , tpGcc  :: !FilePath
  , tpCpp  :: !String
  , tpRoot :: !FilePath
  } deriving (Show)

defaultToolPaths :: FilePath -> ToolPaths
defaultToolPaths root = ToolPaths
  { tpRcc  = root </> "rcc"
  , tpRas  = root </> "ras"
  , tpHsld = root </> "hsld"
  , tpRsim = root </> "rsim"
  , tpGcc  = "/usr/bin/gcc"
  , tpCpp  = "cpp -P -I " ++ (root </> "lib")
                ++ " -I " ++ (root </> "compiler/tests/io")
  , tpRoot = root
  }

-- ---------------------------------------------------------------------------
-- Outcome

data StageError = StageError
  { seStage  :: !String
  , seExit   :: !Int
  , seStderr :: !String
  , seStdout :: !String
  } deriving (Show)

data RunOutcome
  = OK
  | Mismatch !String !String   -- (rcc/sim stdout, host/gcc stdout)
  | StageFail !StageError
  deriving (Show)

-- ---------------------------------------------------------------------------
-- The harness

-- | Run a single fuzzed program through both pipelines.  All artefacts are
-- written to @workDir@ so a failing case can be reproduced by hand and
-- pruned with a delta debugger.
runCase :: ToolPaths -> FilePath -> Program -> Int -> IO RunOutcome
runCase tp workDir prog seed = runCaseFromAst tp workDir prog (caseBaseName seed) (Just seed)

-- | Like 'runCase' but lets the caller specify the artefact basename
-- explicitly.  Used by the shrinker to write 'case_NNN.shrunk' artefacts
-- alongside the originals without overwriting them.
runCaseFromAst
  :: ToolPaths
  -> FilePath
  -> Program
  -> String          -- artefact basename, e.g. "case_000123" or
                     --   "case_000123.shrunk"
  -> Maybe Int       -- seed to record in the .seed file (Nothing skips)
  -> IO RunOutcome
runCaseFromAst tp workDir prog baseName mSeed = do
  createDirectoryIfMissing True workDir
  let p = artefactPaths workDir baseName
  TIO.writeFile (apRccC  p) (renderProgram TargetRcc  prog)
  TIO.writeFile (apHostC p) (renderProgram TargetHost prog)
  case mSeed of
    Just s  -> writeFile (apSeed p) (show s ++ "\n")
    Nothing -> pure ()

  result <- runStages (pipeline tp p)
  case result of
    Left err            -> pure (StageFail err)
    Right (simS, hostS) -> do
      writeFile (apSimOut  p) simS
      writeFile (apHostOut p) hostS
      pure $ if simS == hostS then OK else Mismatch simS hostS

-- ---------------------------------------------------------------------------
-- Per-case artefact paths

data ArtPaths = ArtPaths
  { apRccC    :: !FilePath
  , apHostC   :: !FilePath
  , apS       :: !FilePath
  , apCrt0Obj :: !FilePath
  , apUserObj :: !FilePath
  , apBin     :: !FilePath
  , apHostExe :: !FilePath
  , apSimOut  :: !FilePath
  , apHostOut :: !FilePath
  , apSeed    :: !FilePath
  }

artefactPaths :: FilePath -> String -> ArtPaths
artefactPaths workDir base = ArtPaths
  { apRccC    = workDir </> (base ++ ".rcc.c")
  , apHostC   = workDir </> (base ++ ".host.c")
  , apS       = workDir </> (base ++ ".s")
  , apCrt0Obj = workDir </> (base ++ ".crt0.o")
  , apUserObj = workDir </> (base ++ ".user.o")
  , apBin     = workDir </> (base ++ ".bin")
  , apHostExe = workDir </> (base ++ ".host")
  , apSimOut  = workDir </> (base ++ ".sim.out")
  , apHostOut = workDir </> (base ++ ".host.out")
  , apSeed    = workDir </> (base ++ ".seed")
  }

caseBaseName :: Int -> String
caseBaseName seed = "case_" ++ pad6 seed

pad6 :: Int -> String
pad6 n =
  let s = show n
  in replicate (max 0 (6 - length s)) '0' ++ s

-- ---------------------------------------------------------------------------
-- Stage pipeline

-- | A single stage: a name (for error reporting) and an action that
-- returns either a 'StageError' or the (stdout, stderr) of the spawned
-- process.  The full pipeline is just a list of these run in sequence.
data Stage = Stage
  { stageName :: !String
  , stageRun  :: IO (Either StageError (String, String))
  }

pipeline :: ToolPaths -> ArtPaths -> [Stage]
pipeline tp p =
  [ Stage "rcc"        $ run (tpRcc tp)
      [ "--code-base", "0o100"
      , "--data-base", "0o6600"
      , "--stack-top", "0o7770"
      , "--preprocessor", tpCpp tp
      , apRccC p, "-o", apS p ]
  , Stage "hsasm-crt0" $ run (tpRas tp)
      [ tpRoot tp </> "lib" </> "crt0.s"
      , "--obj-only", "--obj-out", apCrt0Obj p
      , "-D", "RCC_STACK_TOP=0o7770" ]
  , Stage "hsasm-user" $ run (tpRas tp)
      [ apS p, "--obj-only", "--obj-out", apUserObj p
      , "-I", tpRoot tp </> "lib" ]
  , Stage "hsld"       $ run (tpHsld tp)
      [ apCrt0Obj p, apUserObj p
      , "-o", apBin p
      , "--code-base", "0o100"
      , "--data-base", "0o6600" ]
  , Stage "rsim"       $ run (tpRsim tp)
      [ "--mem", "ram:0:0o7770"
      , "--start", "0o100"
      , "--terminal"
      -- Large enough for nested loops + calls without masking codegen bugs
      -- as false timeouts (see 'Fuzz.Gen' loop caps).
      , "--maxcycle", "200000000"
      , apBin p ]
  , Stage "gcc"        $ run (tpGcc tp)
      [ "-std=c99", "-O0", "-w"
      , "-DRRISC_IO_TEST_HOST"
      , "-I", tpRoot tp </> "compiler/tests/io"
      , "-I", tpRoot tp </> "lib"
      , apHostC p, "-o", apHostExe p ]
  , Stage "host"       $ run (apHostExe p) []
  ]
  where
    run = runProc (tpRoot tp)

-- | Run all stages in order.  Returns @(simStdout, hostStdout)@ on
-- success, or the first 'StageError' encountered.  The two stdouts come
-- from the @rsim@ and @host@ stages respectively, identified by name.
runStages :: [Stage] -> IO (Either StageError (String, String))
runStages = go Nothing Nothing
  where
    go _  _  []     = pure $ Left $ StageError "internal" 1 "empty pipeline" ""
    go ms mh [s]    = do
      r <- stageRun s
      case r of
        Left e  -> pure (Left e { seStage = stageName s })
        Right (out, _) -> finish (stageName s) out ms mh
    go ms mh (s:ss) = do
      r <- stageRun s
      case r of
        Left e         -> pure (Left e { seStage = stageName s })
        Right (out, _) ->
          let ms' = if stageName s == "rsim" then Just out else ms
              mh' = if stageName s == "host" then Just out else mh
          in go ms' mh' ss

    finish name out ms mh =
      let ms' = if name == "rsim" then Just out else ms
          mh' = if name == "host" then Just out else mh
      in case (ms', mh') of
           (Just a, Just b) -> pure (Right (a, b))
           _                -> pure $ Left $ StageError "internal" 1
                                  ("missing rsim/host stdout") ""

-- ---------------------------------------------------------------------------
-- Process helper
--
-- gcc internally calls @posix_spawnp("cc1", …)@ and inherits LD_LIBRARY_PATH.
-- When the parent is a Cursor AppImage that path lists AppImage-only libs
-- and cc1 then fails to load.  Always launch tools with a clean PATH and
-- without LD_LIBRARY_PATH inherited from the agent.

cleanEnv :: [(String, String)]
cleanEnv =
  -- UTF-8 locale: ras/hsasm reads source files via lazy Text, so a C locale
  -- chokes on non-ASCII bytes (e.g. comments in lib/crt0.s).
  [ ("PATH",   "/usr/local/sbin:/usr/local/bin:/usr/bin:/bin")
  , ("LANG",   "C.UTF-8")
  , ("LC_ALL", "C.UTF-8")
  , ("HOME",   "/tmp")
  ]

runProc
  :: FilePath -> FilePath -> [String]
  -> IO (Either StageError (String, String))
runProc workDir exe args = do
  exists <- doesFileExist exe
  if not exists
    then pure $ Left $ StageError "" 127 ("missing tool: " <> exe) ""
    else do
      r <- try $ runProcess workDir exe args
      case r of
        Left ex -> pure $ Left $ StageError "" 1
                              (show (ex :: SomeException)) ""
        Right (code, out, err) -> case code of
          ExitSuccess   -> pure (Right (out, err))
          ExitFailure n -> pure $ Left $ StageError "" n err out

-- | Like 'runProc', but returns the exit code instead of treating non-zero
-- as an error.  Still 'Left' for a missing executable or an IO exception.
runProcAllowFailure
  :: FilePath -> FilePath -> [String]
  -> IO (Either StageError (ExitCode, String, String))
runProcAllowFailure workDir exe args = do
  exists <- doesFileExist exe
  if not exists
    then pure $ Left $ StageError "" 127 ("missing tool: " <> exe) ""
    else do
      r <- try $ runProcess workDir exe args
      case r of
        Left ex -> pure $ Left $ StageError "" 1
                          (show (ex :: SomeException)) ""
        Right triple -> pure $ Right triple

runProcess
  :: FilePath -> FilePath -> [String] -> IO (ExitCode, String, String)
runProcess workDir exe args = do
  let cp = (proc exe args)
            { cwd     = Just workDir
            , env     = Just cleanEnv
            , std_in  = NoStream
            , std_out = CreatePipe
            , std_err = CreatePipe
            }
  (_, Just hOut, Just hErr, ph) <- createProcess cp
  out <- hGetAllStrict hOut
  err <- hGetAllStrict hErr
  IO.hClose hOut
  IO.hClose hErr
  code <- waitForProcess ph
  pure (code, out, err)

hGetAllStrict :: IO.Handle -> IO String
hGetAllStrict h = do
  s <- IO.hGetContents h
  length s `seq` pure s
