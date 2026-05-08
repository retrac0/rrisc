{-# LANGUAGE OverloadedStrings #-}
module RRISC.Obj.Format (
  ObjectFile (..),
  Section (..),
  SecRecord (..),
  Linkage (..),
  RelocKind (..),
  BranchKind (..),
  objVersion,
  writeObjectFile,
  renderObject,
  readObjectFile,
  parseObject,
  ObjParseError (..),
  formatObjParseError,
  sectionWords,
  sectionSymbols,
) where

import Control.Monad (foldM)
import Data.Bits ((.&.))
import Data.Char (intToDigit)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Numeric (showIntAtBase)

import RRISC.ISA (wordMask)

-- Object format version. Bump on any breaking format change.
objVersion :: Int
objVersion = 1

data Linkage = LkLocal | LkGlobal | LkExtern | LkWeak
  deriving (Eq, Show)

-- Reloc kinds patch the immediately-preceding placeholder word(s).
data RelocKind
  = RkImm12       -- one word: full 12-bit absolute
  | RkLiImm12     -- two words: lui/addi pair carry the 12-bit value
  | RkJmpTarget12 -- three words: lui/addi/jalr-r0 (jmp)
  | RkCallTarget12-- three words: lui/addi/jalr-r5 (call)
  | RkImm6Pc      -- one word: signed 6-bit PC-relative imm in instruction
  deriving (Eq, Show)

data BranchKind = BkBt | BkBf
  deriving (Eq, Show)

data SecRecord
  = -- | A literal 12-bit word at the current section offset.
    RecWord !Int
  | -- | A run of n zero words.
    RecZero !Int
  | -- | Symbol at the current offset (Nothing) or an explicit offset (Just n).
    RecSym !Text !Linkage !(Maybe Int)
  | -- | Sticky source pointer for following words/relocs.
    RecLoc !FilePath !Int
  | -- | Reloc applies to the preceding placeholder word(s).
    RecReloc !RelocKind !Text !Int
  | -- | Relaxable branch reloc; one placeholder word follows (or already
    --   precedes — see writer convention).
    RecBrel !BranchKind !Text !Int
  deriving (Eq, Show)

data Section = Section
  { secName :: !Text
  , secRecords :: ![SecRecord]
  } deriving (Eq, Show)

data ObjectFile = ObjectFile
  { ofVersion :: !Int
  , ofSources :: ![FilePath]
  , ofSections :: ![Section]
  } deriving (Eq, Show)

-- Compute the resolved word stream of a section (zero-extended for any
-- reloc/brel placeholders not yet patched).
sectionWords :: Section -> [Int]
sectionWords sec = go (secRecords sec)
  where
    go [] = []
    go (RecWord w : rs) = (w .&. wordMask) : go rs
    go (RecZero n : rs) = replicate (max 0 n) 0 ++ go rs
    go (_ : rs) = go rs

-- (name, linkage, offset) for every symbol in the section, in record order.
-- Symbols declared without an explicit offset get the running offset at the
-- point of declaration.
sectionSymbols :: Section -> [(Text, Linkage, Int)]
sectionSymbols sec = go 0 (secRecords sec)
  where
    go _ [] = []
    go !off (r : rs) = case r of
      RecWord _ -> go (off + 1) rs
      RecZero n -> go (off + max 0 n) rs
      RecSym n lk Nothing -> (n, lk, off) : go off rs
      RecSym n lk (Just o) -> (n, lk, o) : go off rs
      RecLoc {} -> go off rs
      RecReloc {} -> go off rs
      RecBrel {} -> go off rs

------------------------------------------------------------
-- Writer
------------------------------------------------------------

writeObjectFile :: FilePath -> ObjectFile -> IO ()
writeObjectFile path obj = TIO.writeFile path (renderObject obj)

renderObject :: ObjectFile -> Text
renderObject obj =
  T.unlines $
    [ "rrisc-obj " <> tshow (ofVersion obj) ]
      ++ map renderSource (ofSources obj)
      ++ concatMap renderSection (ofSections obj)

renderSource :: FilePath -> Text
renderSource fp = "source " <> quoteString fp

renderSection :: Section -> [Text]
renderSection sec =
  ["section " <> secName sec]
    ++ map (("  " <>) . renderRec) (secRecords sec)
    ++ ["endsec"]

renderRec :: SecRecord -> Text
renderRec (RecWord w) = "word " <> octWord w
renderRec (RecZero n) = "zero " <> tshow n
renderRec (RecSym name lk Nothing) =
  "sym " <> name <> " " <> renderLinkage lk
renderRec (RecSym name lk (Just o)) =
  "sym " <> name <> " " <> renderLinkage lk <> " " <> tshow o
renderRec (RecLoc fp ln) =
  "loc " <> quoteString fp <> " " <> tshow ln
renderRec (RecReloc kind sym addend) =
  "reloc " <> renderRelocKind kind <> " " <> sym <> renderAddend addend
renderRec (RecBrel bk sym addend) =
  "brel " <> renderBranchKind bk <> " " <> sym <> renderAddend addend

renderLinkage :: Linkage -> Text
renderLinkage LkLocal = "local"
renderLinkage LkGlobal = "global"
renderLinkage LkExtern = "extern"
renderLinkage LkWeak = "weak"

renderRelocKind :: RelocKind -> Text
renderRelocKind RkImm12 = "imm12"
renderRelocKind RkLiImm12 = "li-imm12"
renderRelocKind RkJmpTarget12 = "jmp-target12"
renderRelocKind RkCallTarget12 = "call-target12"
renderRelocKind RkImm6Pc = "imm6-pc"

renderBranchKind :: BranchKind -> Text
renderBranchKind BkBt = "bt"
renderBranchKind BkBf = "bf"

renderAddend :: Int -> Text
renderAddend 0 = ""
renderAddend n
  | n > 0 = " +" <> tshow n
  | otherwise = " " <> tshow n

octWord :: Int -> Text
octWord w =
  let x = w .&. wordMask
      s = showIntAtBase 8 intToDigit x ""
      s' = if null s then "0" else s
      pad = max 0 (4 - length s')
   in T.pack ("0o" ++ replicate pad '0' ++ s')

tshow :: Show a => a -> Text
tshow = T.pack . show

quoteString :: FilePath -> Text
quoteString fp = "\"" <> T.pack (concatMap escape fp) <> "\""
  where
    escape '"' = "\\\""
    escape '\\' = "\\\\"
    escape '\n' = "\\n"
    escape '\t' = "\\t"
    escape c = [c]

------------------------------------------------------------
-- Reader
------------------------------------------------------------

data ObjParseError = ObjParseError
  { opeFile :: !FilePath
  , opeLine :: !Int
  , opeMsg  :: !Text
  } deriving (Show)

formatObjParseError :: ObjParseError -> Text
formatObjParseError (ObjParseError fp ln msg) =
  T.pack fp <> ":" <> tshow ln <> ": " <> msg

readObjectFile :: FilePath -> IO (Either ObjParseError ObjectFile)
readObjectFile path = do
  txt <- TIO.readFile path
  return (parseObject path txt)

parseObject :: FilePath -> Text -> Either ObjParseError ObjectFile
parseObject fp body = do
  let lns = zip [1 ..] (T.lines body)
  -- Skip leading blank/comment lines, first non-trivial line must be header.
  let rest = dropWhile (isTrivial . snd) lns
  case rest of
    [] -> Left $ ObjParseError fp 1 "empty object file"
    ((hl, header) : after) -> do
      ver <- parseHeader fp hl header
      finalize ver =<< parseBody fp after [] [] Nothing []

  where
    finalize ver (sources, sections) =
      Right $
        ObjectFile
          { ofVersion = ver
          , ofSources = reverse sources
          , ofSections = reverse sections
          }

    parseBody _file [] sources sections Nothing _ = Right (sources, sections)
    parseBody file [] _ _ (Just (secLn, _, _)) _ =
      Left $ ObjParseError file secLn "unterminated section (missing 'endsec')"
    parseBody file ((ln, raw) : rs) sources sections curSec recs =
      let line = T.strip (stripComment raw)
       in if T.null line
            then parseBody file rs sources sections curSec recs
            else case T.words line of
              ("source" : _) -> case curSec of
                Just _ ->
                  Left $ ObjParseError file ln "'source' not allowed inside section"
                Nothing -> do
                  s <- parseQuotedTail file ln (T.drop 6 line)
                  parseBody file rs (s : sources) sections curSec recs
              ("section" : nm : _) -> case curSec of
                Just (sl, _, _) ->
                  Left $ ObjParseError file ln $
                    "nested 'section' (previous opened at line " <> tshow sl <> ")"
                Nothing ->
                  parseBody file rs sources sections (Just (ln, nm, [])) recs
              ["endsec"] -> case curSec of
                Nothing ->
                  Left $ ObjParseError file ln "'endsec' without matching 'section'"
                Just (_, nm, _) ->
                  let sec = Section nm (reverse recs)
                   in parseBody file rs sources (sec : sections) Nothing []
              _ -> case curSec of
                Nothing ->
                  Left $ ObjParseError file ln $
                    "unexpected token outside section: " <> T.takeWhile (/= ' ') line
                Just _ -> do
                  rec_ <- parseRecord file ln line
                  parseBody file rs sources sections curSec (rec_ : recs)

    parseHeader file ln raw =
      case T.words (T.strip raw) of
        ["rrisc-obj", v] -> case readsT v of
          Just n
            | n == objVersion -> Right n
            | otherwise ->
                Left $ ObjParseError file ln $
                  "unsupported object version " <> tshow n <>
                  " (this build expects " <> tshow objVersion <> ")"
          Nothing ->
            Left $ ObjParseError file ln $
              "malformed version in 'rrisc-obj' header: " <> v
        _ ->
          Left $ ObjParseError file ln $
            "expected 'rrisc-obj <version>' header, got: " <> T.strip raw

isTrivial :: Text -> Bool
isTrivial t =
  let s = T.strip (stripComment t)
   in T.null s

stripComment :: Text -> Text
stripComment t = T.takeWhile (/= ';') t

parseQuotedTail :: FilePath -> Int -> Text -> Either ObjParseError FilePath
parseQuotedTail fp ln raw =
  case parseQuoted (T.strip raw) of
    Just (s, rest) | T.null (T.strip rest) -> Right s
    _ -> Left $ ObjParseError fp ln "expected a quoted \"path\""

parseQuoted :: Text -> Maybe (FilePath, Text)
parseQuoted t = case T.uncons t of
  Just ('"', rest) -> go rest []
  _ -> Nothing
  where
    go s acc = case T.uncons s of
      Nothing -> Nothing
      Just ('"', rest) -> Just (reverse acc, rest)
      Just ('\\', rest) -> case T.uncons rest of
        Just (c, rest') -> go rest' (unescape c : acc)
        Nothing -> Nothing
      Just (c, rest) -> go rest (c : acc)

    unescape 'n' = '\n'
    unescape 't' = '\t'
    unescape c = c

parseRecord :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseRecord fp ln line =
  case T.words line of
    [] -> Left $ ObjParseError fp ln "empty record"
    (kw : _) -> case kw of
      "word" -> parseWord fp ln (T.drop 4 line)
      "zero" -> parseZero fp ln (T.drop 4 line)
      "sym" -> parseSym fp ln (T.drop 3 line)
      "loc" -> parseLoc fp ln (T.drop 3 line)
      "reloc" -> parseReloc fp ln (T.drop 5 line)
      "brel" -> parseBrel fp ln (T.drop 4 line)
      _ ->
        Left $ ObjParseError fp ln $ "unknown record kind '" <> kw <> "'"

parseWord :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseWord fp ln raw =
  case T.words (T.strip raw) of
    [v] -> RecWord <$> parseInt fp ln v
    _ -> Left $ ObjParseError fp ln "'word' takes one value (use one record per word)"

parseZero :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseZero fp ln raw =
  case T.words (T.strip raw) of
    [v] -> do
      n <- parseInt fp ln v
      if n < 0
        then Left $ ObjParseError fp ln "'zero' count must be non-negative"
        else Right (RecZero n)
    _ -> Left $ ObjParseError fp ln "'zero' takes one count"

parseSym :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseSym fp ln raw =
  case T.words (T.strip raw) of
    [name, lkTok] -> do
      lk <- parseLinkage fp ln lkTok
      Right (RecSym name lk Nothing)
    [name, lkTok, offTok] -> do
      lk <- parseLinkage fp ln lkTok
      off <- parseInt fp ln offTok
      Right (RecSym name lk (Just off))
    _ -> Left $ ObjParseError fp ln "expected 'sym <name> <linkage> [<offset>]'"

parseLoc :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseLoc fp ln raw =
  case parseQuoted (T.strip raw) of
    Just (path, rest) -> case T.words (T.strip rest) of
      [v] -> RecLoc path <$> parseInt fp ln v
      _ -> Left $ ObjParseError fp ln "expected 'loc \"<path>\" <line>'"
    Nothing -> Left $ ObjParseError fp ln "expected 'loc \"<path>\" <line>'"

parseReloc :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseReloc fp ln raw =
  case T.words (T.strip raw) of
    (kindTok : sym : addTail) -> do
      kind <- parseRelocKind fp ln kindTok
      addend <- parseAddendTail fp ln addTail
      Right (RecReloc kind sym addend)
    _ -> Left $ ObjParseError fp ln "expected 'reloc <kind> <symbol> [<addend>]'"

parseBrel :: FilePath -> Int -> Text -> Either ObjParseError SecRecord
parseBrel fp ln raw =
  case T.words (T.strip raw) of
    (bkTok : sym : addTail) -> do
      bk <- parseBranchKind fp ln bkTok
      addend <- parseAddendTail fp ln addTail
      Right (RecBrel bk sym addend)
    _ -> Left $ ObjParseError fp ln "expected 'brel <bt|bf> <symbol> [<addend>]'"

parseAddendTail :: FilePath -> Int -> [Text] -> Either ObjParseError Int
parseAddendTail _ _ [] = Right 0
parseAddendTail fp ln [v] =
  let v' = if T.isPrefixOf "+" v then T.drop 1 v else v
   in parseInt fp ln v'
parseAddendTail fp ln _ =
  Left $ ObjParseError fp ln "trailing tokens after addend"

parseLinkage :: FilePath -> Int -> Text -> Either ObjParseError Linkage
parseLinkage _ _ "local" = Right LkLocal
parseLinkage _ _ "global" = Right LkGlobal
parseLinkage _ _ "extern" = Right LkExtern
parseLinkage _ _ "weak" = Right LkWeak
parseLinkage fp ln t =
  Left $ ObjParseError fp ln $ "unknown linkage class '" <> t <> "'"

parseRelocKind :: FilePath -> Int -> Text -> Either ObjParseError RelocKind
parseRelocKind _ _ "imm12" = Right RkImm12
parseRelocKind _ _ "li-imm12" = Right RkLiImm12
parseRelocKind _ _ "jmp-target12" = Right RkJmpTarget12
parseRelocKind _ _ "call-target12" = Right RkCallTarget12
parseRelocKind _ _ "imm6-pc" = Right RkImm6Pc
parseRelocKind fp ln t =
  Left $ ObjParseError fp ln $ "unknown reloc kind '" <> t <> "'"

parseBranchKind :: FilePath -> Int -> Text -> Either ObjParseError BranchKind
parseBranchKind _ _ "bt" = Right BkBt
parseBranchKind _ _ "bf" = Right BkBf
parseBranchKind fp ln t =
  Left $ ObjParseError fp ln $ "unknown branch kind '" <> t <> "'"

parseInt :: FilePath -> Int -> Text -> Either ObjParseError Int
parseInt fp ln tok =
  case readsT tok of
    Just n -> Right n
    Nothing ->
      Left $ ObjParseError fp ln $ "malformed integer literal '" <> tok <> "'"

readsT :: Text -> Maybe Int
readsT t =
  let (sign, body) = case T.uncons t of
        Just ('-', rest) -> (-1, rest)
        Just ('+', rest) -> (1, rest)
        _ -> (1, t)
   in fmap (sign *) (readBody body)
  where
    readBody body = case T.unpack body of
      ('0' : 'o' : digits)
        | not (null digits) -> readBase 8 digits
      ('0' : 'O' : digits)
        | not (null digits) -> readBase 8 digits
      ('0' : 'x' : digits)
        | not (null digits) -> readBase 16 digits
      ('0' : 'X' : digits)
        | not (null digits) -> readBase 16 digits
      ('0' : 'b' : digits)
        | not (null digits) -> readBase 2 digits
      ('0' : 'B' : digits)
        | not (null digits) -> readBase 2 digits
      digits | not (null digits) -> readBase 10 digits
      _ -> Nothing

    readBase b s = foldM (acc b) 0 s

    acc b n c = case digitVal c of
      Just d | d < b -> Just (n * b + d)
      _ -> Nothing

    digitVal c
      | c >= '0' && c <= '9' = Just (fromEnum c - fromEnum '0')
      | c >= 'a' && c <= 'f' = Just (fromEnum c - fromEnum 'a' + 10)
      | c >= 'A' && c <= 'F' = Just (fromEnum c - fromEnum 'A' + 10)
      | otherwise = Nothing
