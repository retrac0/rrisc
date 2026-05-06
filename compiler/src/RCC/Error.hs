module RCC.Error
  ( Pos(..)
  , Span(..)
  , Severity(..)
  , Diagnostic(..)
  , noSpan
  , mkError
  , mkWarn
  , formatDiagnostic
  ) where

import Data.Text (Text)
import qualified Data.Text as T

data Pos = Pos
  { posFile :: FilePath
  , posLine :: Int
  , posCol  :: Int
  } deriving (Show, Eq, Ord)

data Span = Span
  { spanStart :: Pos
  , spanEnd   :: Pos
  } deriving (Show, Eq)

noSpan :: Span
noSpan = Span p p where p = Pos "<unknown>" 0 0

data Severity = SevError | SevWarning
  deriving (Show, Eq)

data Diagnostic = Diagnostic
  { diagSpan     :: Span
  , diagSeverity :: Severity
  , diagMessage  :: Text
  } deriving (Show, Eq)

mkError :: Span -> Text -> Diagnostic
mkError sp msg = Diagnostic sp SevError msg

mkWarn :: Span -> Text -> Diagnostic
mkWarn sp msg = Diagnostic sp SevWarning msg

formatDiagnostic :: Diagnostic -> Text
formatDiagnostic Diagnostic{diagSpan, diagSeverity, diagMessage} =
  T.pack (posFile s) <> ":" <> tshow (posLine s) <> ":"
  <> tshow (posCol s) <> ": " <> sevStr <> ": " <> diagMessage
  where
    s      = spanStart diagSpan
    sevStr = case diagSeverity of
      SevError   -> "error"
      SevWarning -> "warning"
    tshow  = T.pack . show
