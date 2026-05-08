{-# LANGUAGE LambdaCase #-}
-- | rcc-fuzz: differential fuzzer for the RRISC C compiler.
--
-- Generates random programs in the rcc subset of C, compiles each one
-- through the full RRISC toolchain ('rcc' → 'hsasm' → 'hsld' → 'rsim') and
-- through host 'gcc -DRRISC_IO_TEST_HOST', and reports any cases where the
-- two stdouts differ (that's a likely 'rcc' bug, with the no-UB contract
-- in "Fuzz.Gen" carrying the burden of "this program means the same thing
-- on both targets").
--
-- Typical usage from the repo root:
--
-- @
--   cabal run -v0 rcc-fuzz -- --count 200 --jobs 4
--   cabal run -v0 rcc-fuzz -- --start-seed 12345 --count 1
--   cabal run -v0 rcc-fuzz -- --replay 12345
-- @
module Main (main) where

import Control.Concurrent.Async (forConcurrently_)
import Control.Concurrent.MVar  (newMVar, withMVar)
import Control.Monad (when)
import Data.IORef (atomicModifyIORef', newIORef, readIORef)
import qualified Data.Text.IO as TIO
import System.Directory
  ( copyFile
  , createDirectoryIfMissing
  , doesDirectoryExist
  , doesFileExist
  , getCurrentDirectory
  , listDirectory
  , removeFile
  )
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess, exitWith, ExitCode (..))
import System.FilePath ((</>))
import System.IO (hFlush, hPutStrLn, stdout, stderr)

import Fuzz.Gen    (defaultConfig, genProgram, GenConfig (..))
import qualified Fuzz.Print as P
import Fuzz.Print  (Target (..))
import Fuzz.Run
import Fuzz.Shrink (shrinkProgram)

-- ---------------------------------------------------------------------------
-- Options

data Mode
  = MFuzz
  | MReplay !Int
  | MShrink !Int            -- replay seed N, then shrink the failure
  | MEmit   !Int !Target    -- which version to print
  deriving (Show)

data Opts = Opts
  { oMode         :: !Mode
  , oCount        :: !Int
  , oStartSeed    :: !Int
  , oJobs         :: !Int
  , oWorkDir      :: !FilePath
  , oFailDir      :: !FilePath
  , oKeepGood     :: !Bool
  , oClean        :: !Bool
  , oRoot         :: !FilePath
  , oVerbose      :: !Bool
  , oNoCalls      :: !Bool
  , oNoLoops      :: !Bool
  , oNoArrays     :: !Bool
  , oMaxStmts     :: !(Maybe Int)
  , oMaxExpr      :: !(Maybe Int)
  , oMaxLoopDepth :: !(Maybe Int)
  , oAutoShrink   :: !Bool
  } deriving (Show)

defaultOpts :: FilePath -> Opts
defaultOpts root = Opts
  { oMode         = MFuzz
  , oCount        = 100
  , oStartSeed    = 1
  , oJobs         = 1
  , oWorkDir      = root </> "compiler" </> "tests" </> "fuzz-work"
  , oFailDir      = root </> "compiler" </> "tests" </> "fuzz-fail"
  , oKeepGood     = False
  , oClean        = False
  , oRoot         = root
  , oVerbose      = False
  , oNoCalls      = False
  , oNoLoops      = False
  , oNoArrays     = False
  , oMaxStmts     = Nothing
  , oMaxExpr      = Nothing
  , oMaxLoopDepth = Nothing
  , oAutoShrink   = False
  }

parseArgs :: [String] -> Opts -> Either String Opts
parseArgs []                   o = Right o
parseArgs ("--count":n:r)      o = readInt n "--count"      >>= \k -> parseArgs r o { oCount     = k }
parseArgs ("--start-seed":n:r) o = readInt n "--start-seed" >>= \k -> parseArgs r o { oStartSeed = k }
parseArgs ("--jobs":n:r)       o = readInt n "--jobs"       >>= \k -> parseArgs r o { oJobs      = max 1 k }
parseArgs ("--work":d:r)       o = parseArgs r o { oWorkDir = d }
parseArgs ("--fail":d:r)       o = parseArgs r o { oFailDir = d }
parseArgs ("--keep":r)         o = parseArgs r o { oKeepGood = True }
parseArgs ("--clean":r)        o = parseArgs r o { oClean    = True }
parseArgs ("--verbose":r)      o = parseArgs r o { oVerbose  = True }
parseArgs ("-v":r)             o = parseArgs r o { oVerbose  = True }
parseArgs ("--root":d:r)       o = parseArgs r o { oRoot = d }
parseArgs ("--no-calls":r)     o = parseArgs r o { oNoCalls  = True }
parseArgs ("--no-loops":r)     o = parseArgs r o { oNoLoops  = True }
parseArgs ("--no-arrays":r)    o = parseArgs r o { oNoArrays = True }
parseArgs ("--max-stmts":n:r)       o = readInt n "--max-stmts"       >>= \k -> parseArgs r o { oMaxStmts     = Just k }
parseArgs ("--max-expr":n:r)        o = readInt n "--max-expr"        >>= \k -> parseArgs r o { oMaxExpr      = Just k }
parseArgs ("--max-loop-depth":n:r)  o = readInt n "--max-loop-depth"  >>= \k -> parseArgs r o { oMaxLoopDepth = Just k }
parseArgs ("--replay":n:r)     o = readInt n "--replay"     >>= \k -> parseArgs r o { oMode = MReplay k }
parseArgs ("--shrink":n:r)     o = readInt n "--shrink"     >>= \k -> parseArgs r o { oMode = MShrink k }
parseArgs ("--auto-shrink":r)  o = parseArgs r o { oAutoShrink = True }
parseArgs ("--emit":n:r)       o = readInt n "--emit"       >>= \k -> parseArgs r o { oMode = MEmit k TargetRcc }
parseArgs ("--emit-host":n:r)  o = readInt n "--emit-host"  >>= \k -> parseArgs r o { oMode = MEmit k TargetHost }
parseArgs ("--help":_)         _ = Left helpText
parseArgs ("-h":_)             _ = Left helpText
parseArgs (x:_)                _ = Left ("unknown option: " <> x <> "\n" <> helpText)

readInt :: String -> String -> Either String Int
readInt s flag = case reads s of
  [(n, "")] -> Right n
  _         -> Left (flag <> " expects an integer, got: " <> s)

helpText :: String
helpText = unlines
  [ "Usage: rcc-fuzz [options]"
  , ""
  , "Differential fuzzer for rcc.  Generates random programs in the rcc"
  , "subset of C, runs them through both the RRISC toolchain and host gcc,"
  , "and reports any output mismatches."
  , ""
  , "Options:"
  , "  --count N           number of seeds to test (default: 100)"
  , "  --start-seed N      first seed (default: 1)"
  , "  --jobs N            parallel jobs (default: 1)"
  , "  --work DIR          scratch dir (default: compiler/tests/fuzz-work)"
  , "  --fail DIR          where to copy failing cases (default: compiler/tests/fuzz-fail)"
  , "  --keep              keep all cases on disk (default: only failures)"
  , "  --clean             wipe failure dir before running (recommended after rcc fixes)"
  , "  --verbose | -v      print per-case status"
  , "  --root DIR          repo root (default: cwd)"
  , "  --no-calls          do not generate user-defined function calls"
  , "  --no-loops          do not generate while/for loops"
  , "  --no-arrays         do not generate array locals"
  , "  --max-stmts N       per-block statement cap"
  , "  --max-expr N        expression nesting cap"
  , "  --max-loop-depth N  loop nesting cap (worst-case work is loopcap^N)"
  , "  --replay N          rebuild + run only seed N"
  , "  --shrink N          replay seed N; if it fails, minimize and write *.shrunk.* artefacts"
  , "  --auto-shrink       in fuzz mode, shrink every failure into oFailDir"
  , "  --emit N            print the rcc-target .c source for seed N and exit"
  , "  --emit-host N       print the host-gcc .c source for seed N and exit"
  , "  -h, --help          show this message"
  ]

-- ---------------------------------------------------------------------------
-- Main

main :: IO ()
main = do
  cwd <- getCurrentDirectory
  rawArgs <- getArgs
  opts0 <- case parseArgs rawArgs (defaultOpts cwd) of
    Left err -> hPutStrLn stderr err >> exitFailure
    Right o  -> pure o
  -- If --root was given on the CLI, re-root the work/fail dirs to it
  -- *unless* the user explicitly overrode them with --work/--fail.  We
  -- detect "explicit override" by comparing to the cwd-rooted default.
  let cwdDefaults = defaultOpts cwd
      opts =
        if oRoot opts0 == cwd
          then opts0
          else opts0
            { oWorkDir = if oWorkDir opts0 == oWorkDir cwdDefaults
                          then oRoot opts0 </> "compiler" </> "tests" </> "fuzz-work"
                          else oWorkDir opts0
            , oFailDir = if oFailDir opts0 == oFailDir cwdDefaults
                          then oRoot opts0 </> "compiler" </> "tests" </> "fuzz-fail"
                          else oFailDir opts0
            }
  let cfg = applyCfg opts defaultConfig
  case oMode opts of
    MEmit s tgt -> do
      TIO.putStr (P.renderProgram tgt (genProgram cfg s))
      exitSuccess
    MReplay s -> do
      r <- runOne opts cfg s
      exitOnRun r
    MShrink s -> do
      r <- runOne opts cfg s
      case r of
        OK -> do
          putStrLn ("seed=" <> show s <> " passed; nothing to shrink")
          exitSuccess
        _  -> do
          shrinkOne opts cfg s r
          exitWith (ExitFailure 2)
    MFuzz -> runMany opts cfg

applyCfg :: Opts -> GenConfig -> GenConfig
applyCfg o c = c
  { cfgUseCalls   = not (oNoCalls  o) && cfgUseCalls   c
  , cfgUseLoops   = not (oNoLoops  o) && cfgUseLoops   c
  , cfgUseArrays  = not (oNoArrays o) && cfgUseArrays  c
  , cfgMaxStmts   = maybe (cfgMaxStmts   c) id (oMaxStmts     o)
  , cfgMaxExprDep = maybe (cfgMaxExprDep c) id (oMaxExpr      o)
  , cfgMaxLoopDep = maybe (cfgMaxLoopDep c) id (oMaxLoopDepth o)
  }

exitOnRun :: RunOutcome -> IO ()
exitOnRun OK             = exitSuccess
exitOnRun (Mismatch _ _) = exitWith (ExitFailure 2)
exitOnRun (StageFail _)      = exitWith (ExitFailure 3)

runOne :: Opts -> GenConfig -> Int -> IO RunOutcome
runOne opts cfg seed = do
  when (oClean opts) (cleanDir (oFailDir opts))
  createDirectoryIfMissing True (oWorkDir opts)
  let prog = genProgram cfg seed
      tp   = defaultToolPaths (oRoot opts)
  result <- runCase tp (oWorkDir opts) prog seed
  reportOne True opts seed result
  promoteFailureIfNeeded opts seed result
  pure result

runMany :: Opts -> GenConfig -> IO ()
runMany opts cfg = do
  when (oClean opts) $ do
    cleanDir (oFailDir opts)
    cleanDir (oWorkDir opts)
  createDirectoryIfMissing True (oWorkDir opts)
  createDirectoryIfMissing True (oFailDir opts)
  okCount    <- newIORef (0 :: Int)
  failCount  <- newIORef (0 :: Int)
  stageCount <- newIORef (0 :: Int)
  printLock  <- newMVar ()
  let seeds = [oStartSeed opts .. oStartSeed opts + oCount opts - 1]
      tp    = defaultToolPaths (oRoot opts)
      jobs  = oJobs opts
      partition = chunkRoundRobin jobs seeds
  forConcurrently_ partition $ \chunk ->
    mapM_ (\s -> do
            let prog = genProgram cfg s
            r <- runCase tp (oWorkDir opts) prog s
            withMVar printLock $ \_ -> reportOne (oVerbose opts) opts s r
            promoteFailureIfNeeded opts s r
            when (oAutoShrink opts && isFailure r) $
              shrinkOne opts cfg s r
            case r of
              OK         -> atomicModifyIORef' okCount    (\n -> (n+1, ()))
              Mismatch{} -> atomicModifyIORef' failCount  (\n -> (n+1, ()))
              StageFail{}    -> atomicModifyIORef' stageCount (\n -> (n+1, ()))) chunk
  ok <- readIORef okCount
  fl <- readIORef failCount
  st <- readIORef stageCount
  putStrLn $ "rcc-fuzz: " <> show ok <> " ok, " <> show fl
          <> " mismatches, " <> show st <> " stage failures"
  hFlush stdout
  if fl == 0 && st == 0 then exitSuccess else exitWith (ExitFailure 1)

chunkRoundRobin :: Int -> [a] -> [[a]]
chunkRoundRobin k xs = [ pickEvery k i xs | i <- [0 .. k-1] ]
  where
    pickEvery n i ys = [ y | (j, y) <- zip [0..] ys, j `mod` n == i ]

reportOne :: Bool -> Opts -> Int -> RunOutcome -> IO ()
reportOne verbose _opts seed res = case res of
  OK -> when verbose $ do
    putStrLn ("ok     seed=" <> show seed)
    hFlush stdout
  Mismatch sa sb -> do
    putStrLn ("MISMATCH seed=" <> show seed)
    putStrLn ("  rcc/sim  stdout (first 200 bytes): " <> show (take 200 sa))
    putStrLn ("  host/gcc stdout (first 200 bytes): " <> show (take 200 sb))
    hFlush stdout
  StageFail e -> do
    putStrLn ("STAGE-FAIL seed=" <> show seed
              <> " stage=" <> seStage e
              <> " exit="  <> show (seExit e))
    when (not (null (seStderr e))) $
      putStrLn ("  stderr: " <> take 800 (seStderr e))
    when (not (null (seStdout e))) $
      putStrLn ("  stdout: " <> take 800 (seStdout e))
    hFlush stdout

-- Copy the on-disk artefacts of a failing case into oFailDir so subsequent
-- successful runs in the same workdir don't overwrite them.
promoteFailureIfNeeded :: Opts -> Int -> RunOutcome -> IO ()
promoteFailureIfNeeded opts seed = \case
  OK -> pure ()
  _  -> do
    createDirectoryIfMissing True (oFailDir opts)
    let names =
          [ caseName seed ++ ".rcc.c"
          , caseName seed ++ ".host.c"
          , caseName seed ++ ".s"
          , caseName seed ++ ".bin"
          , caseName seed ++ ".sim.out"
          , caseName seed ++ ".host.out"
          , caseName seed ++ ".seed"
          ]
    mapM_ (\n -> do
        let src = oWorkDir opts </> n
            dst = oFailDir opts </> n
        ok <- doesFileExist src
        when ok $ copyFile src dst) names

caseName :: Int -> FilePath
caseName seed =
  "case_" ++ replicate (max 0 (6 - length (show seed))) '0' ++ show seed

isFailure :: RunOutcome -> Bool
isFailure OK = False
isFailure _  = True

-- | True if @r@ is the same kind of failure as @orig@.  A 'Mismatch' is
-- the same kind as another 'Mismatch'; a 'StageFail' is the same kind
-- only when both occur in the same stage (so we don't accept an
-- unrelated link-error candidate when triaging an rsim mismatch).
sameFailureKind :: RunOutcome -> RunOutcome -> Bool
sameFailureKind OK              _               = False
sameFailureKind _               OK              = False
sameFailureKind Mismatch{}      Mismatch{}      = True
sameFailureKind (StageFail e1)  (StageFail e2)  = seStage e1 == seStage e2
sameFailureKind _               _               = False

-- ---------------------------------------------------------------------------
-- Shrinking

-- | Replay the failing seed, then iteratively minimize it.  The minimized
-- artefacts go into @<workdir>/case_NNNNNN.shrunk.*@ and are then
-- copied into the fail dir so they sit next to the original.
--
-- The oracle accepts a candidate only if it triggers the *same kind* of
-- failure as the original: a mismatch shrinks to a mismatch, a stage
-- failure shrinks to a stage failure at the same stage.  Without this
-- restriction the shrinker would happily produce ill-typed reproducers
-- (e.g. a call to a function it just dropped) which all stage-fail at
-- some other point and are useless for triage.
shrinkOne :: Opts -> GenConfig -> Int -> RunOutcome -> IO ()
shrinkOne opts cfg seed orig = do
  let prog0 = genProgram cfg seed
      tp    = defaultToolPaths (oRoot opts)
      base  = caseName seed ++ ".shrunk"
      oracle prog = do
        r <- runCaseFromAst tp (oWorkDir opts) prog base Nothing
        pure (sameFailureKind orig r)
  putStrLn ("shrinking seed=" <> show seed <> " ...")
  hFlush stdout
  shrunk <- shrinkProgram oracle prog0
  -- Make sure the on-disk shrunk artefacts are the minimized ones.
  _ <- runCaseFromAst tp (oWorkDir opts) shrunk base Nothing
  -- Promote into the fail directory alongside the original.
  let shrunkArtefacts =
        [ base ++ ".rcc.c"
        , base ++ ".host.c"
        , base ++ ".s"
        , base ++ ".bin"
        , base ++ ".sim.out"
        , base ++ ".host.out"
        ]
  createDirectoryIfMissing True (oFailDir opts)
  mapM_ (\n -> do
      let src = oWorkDir opts </> n
          dst = oFailDir opts </> n
      ok <- doesFileExist src
      when ok $ copyFile src dst) shrunkArtefacts
  putStrLn ("  → " <> (oFailDir opts </> base ++ ".rcc.c"))
  hFlush stdout

-- | Wipe every regular file in the directory.  Used by --clean so a
-- failing run from before an rcc fix doesn't masquerade as a current
-- failure (cf. the old @case_000026@ that sat in @fuzz-fail/@ with
-- matching outputs).
cleanDir :: FilePath -> IO ()
cleanDir d = do
  exists <- doesDirectoryExist d
  when exists $ do
    entries <- listDirectory d
    mapM_ (\e -> do
        let p = d </> e
        isFile <- doesFileExist p
        when isFile (removeFile p)) entries
