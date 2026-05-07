{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm.Types (
  AsmError (..),
  formatAsmError,
  RawLine (..),
  SourceLine (..),
  Stmt (..),
  MacroDef (..),
) where

import Data.Text (Text)
import qualified Data.Text as T

data AsmError = AsmError FilePath Int Text
  deriving (Show)

formatAsmError :: AsmError -> Text
formatAsmError (AsmError fp ln msg) =
  T.pack fp <> ":" <> T.pack (show ln) <> ": " <> msg

data RawLine = RawLine
  { rlPath :: !FilePath
  , rlLineNo :: !Int
  , rlText :: !Text
  } deriving (Show)

data SourceLine = SourceLine
  { slPath :: !FilePath
  , slLineNo :: !Int
  , slText :: !Text
  , slSourceIx :: !Int
  } deriving (Show)

data Stmt = Stmt
  { stPath :: !FilePath
  , stLine :: !Int
  , stLabels :: ![Text]
  , stMnem :: !Text
  , stOps :: !Text
  , stAddr :: !Int
  , stSourceIx :: !Int
  } deriving (Show)

data MacroDef = MacroDef
  { mdParams :: ![Text]
  , mdBody :: ![RawLine]
  , mdPath :: !FilePath
  , mdLine :: !Int
  } deriving (Show)
