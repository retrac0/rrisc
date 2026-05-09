-- | Negative oracle: same C source is checked with @gcc -fsyntax-only@ and
-- @rcc@ (through the preprocessor).  Agreement means both accept (exit 0) or
-- both reject (non-zero).  A mismatch flags spec drift or a silent acceptance bug.
module Fuzz.NegativeRun
  ( NegativeOutcome (..)
  , negativeArtPaths
  , runNegativeCase
  ) where

import Data.Text (Text)
import qualified Data.Text.IO as TIO
import System.Directory (createDirectoryIfMissing)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))

import Fuzz.Run (ToolPaths (..), StageError (..), runProcAllowFailure)

-- ---------------------------------------------------------------------------
-- Paths for one negative case

data NegativeArtPaths = NegativeArtPaths
  { napC  :: !FilePath
  , napS  :: !FilePath
  } deriving (Show)

negativeArtPaths :: FilePath -> String -> NegativeArtPaths
negativeArtPaths workDir base = NegativeArtPaths
  { napC = workDir </> (base ++ ".negative.c")
  , napS = workDir </> (base ++ ".negative.s")
  }

-- ---------------------------------------------------------------------------
-- Outcome

data NegativeOutcome
  = AgreeBothReject
  | AgreeBothAccept
  -- | @NegativeMismatch rccOk gccOk@ when the two compilers disagree.
  | NegativeMismatch !Bool !Bool
  | ToolFail !StageError
  deriving (Show)

-- ---------------------------------------------------------------------------
-- Runner

runNegativeCase
  :: ToolPaths
  -> FilePath   -- ^ work directory (created if missing)
  -> String     -- ^ basename, e.g. @case_000042@
  -> Text       -- ^ C source
  -> IO NegativeOutcome
runNegativeCase tp workDir baseName src = do
  createDirectoryIfMissing True workDir
  let p = negativeArtPaths workDir baseName
  TIO.writeFile (napC p) src

  gccR <- runProcAllowFailure (tpRoot tp) (tpGcc tp) $
    [ "-fsyntax-only"
    , "-std=c99"
    , "-w"
    , "-DRRISC_IO_TEST_HOST"
    , "-I", tpRoot tp </> "compiler" </> "tests" </> "io"
    , "-I", tpRoot tp </> "lib"
    , napC p
    ]
  case gccR of
    Left e -> pure $ ToolFail e { seStage = "gcc-syntax-only" }
    Right (gccCode, _, _) -> do
      rccR <- runProcAllowFailure (tpRoot tp) (tpRcc tp)
        [ "--code-base", "0o100"
        , "--data-base", "0o6600"
        , "--stack-top", "0o7770"
        , "--preprocessor", tpCpp tp
        , napC p
        , "-o", napS p
        ]
      case rccR of
        Left e -> pure $ ToolFail e { seStage = "rcc" }
        Right (rccCode, _, _) ->
          let gccOk = case gccCode of ExitSuccess -> True; ExitFailure _ -> False
              rccOk = case rccCode of ExitSuccess -> True; ExitFailure _ -> False
          in pure $ case (rccOk, gccOk) of
            (False, False) -> AgreeBothReject
            (True, True)   -> AgreeBothAccept
            _              -> NegativeMismatch rccOk gccOk
