module Main (main) where

import Control.Monad (when)
import Data.List (isPrefixOf, sortBy)
import Data.Ord (comparing)
import Data.Version (showVersion)
import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (replaceExtension, takeExtension)
import System.IO (hPutStrLn, stderr)
import Text.Printf (printf)

import Paths_rrisc_tools (version)

import RRISC.Asm
import RRISC.Obj.Format
  ( Linkage (..)
  , ObjectFile (..)
  , Section (..)
  , readObjectFile
  , sectionSymbols
  , writeObjectFile
  , formatObjParseError
  )

usage :: String
usage =
  unlines
    [ "Usage: ras source.s [-o output] [-I dir]... [-D NAME=value]..."
    , "                      [--format bin|readmemb] [--list]"
    , "       (default: emit relocatable object .o; use --format for flat .bin/.mem)"
    , "       ras --dump-syms file.o"
    , "  -V, --version         print version and exit"
    ]

-- | Nothing = relocatable object; Just fmt = flat image (bin|readmemb).
data Mode
  = ModeAssemble
      FilePath -- src
      (Maybe FilePath) -- -o
      [FilePath] -- -I
      (M.Map T.Text T.Text) -- -D
      (Maybe String) -- Just "bin"|"readmemb" when --format given
      Bool -- --list (flat only)
  | ModeDumpSyms FilePath

main :: IO ()
main = do
  args <- getArgs
  when (args == ["--version"] || args == ["-V"]) $ do
    putStrLn $ "ras " ++ showVersion version
    exitSuccess
  case parseArgs args of
    Nothing -> hPutStrLn stderr usage >> exitFailure
    Just (ModeDumpSyms path) -> dumpSyms path
    Just m@ModeAssemble{} -> runAssemble m

runAssemble :: Mode -> IO ()
runAssemble ModeDumpSyms{} = error "unreachable"
runAssemble (ModeAssemble src outArg incDirs cliDefines mFmt doList) = do
  case mFmt of
    Nothing -> do
      when doList $ hPutStrLn stderr "ras: --list requires --format bin|readmemb" >> exitFailure
      eObj <- assembleFileToObject src incDirs cliDefines
      case eObj of
        Left err -> TIO.hPutStrLn stderr (formatAsmError err) >> exitFailure
        Right obj -> do
          let objPath = case outArg of
                Just p -> p
                Nothing ->
                  if null (takeExtension src)
                    then src ++ ".o"
                    else replaceExtension src ".o"
          writeObjectFile objPath obj
          exitSuccess
    Just fmt -> do
      eAsm <- assembleFile src incDirs cliDefines
      case eAsm of
        Left err -> TIO.hPutStrLn stderr (formatAsmError err) >> exitFailure
        Right res -> do
          let defExt = if fmt == "readmemb" then ".mem" else ".bin"
              outPath = case outArg of
                Just p -> p
                Nothing ->
                  if null (takeExtension src)
                    then src ++ defExt
                    else replaceExtension src defExt
          if fmt == "readmemb"
            then writeReadmemb outPath (arWords res)
            else writeBinary outPath (arWords res)
          if doList
            then formatListing (arFlatLines res) (arListing res) >>= TIO.putStrLn
            else return ()
          exitSuccess

dumpSyms :: FilePath -> IO ()
dumpSyms path = do
  e <- readObjectFile path
  case e of
    Left err -> TIO.hPutStrLn stderr (formatObjParseError err) >> exitFailure
    Right obj -> do
      let rows = collectSymRows obj
          sorted = sortBy (comparing (\(_, _, _, off) -> off)) rows
      mapM_ printRow sorted
      exitSuccess

collectSymRows :: ObjectFile -> [(T.Text, T.Text, Linkage, Int)]
collectSymRows obj =
  [ (secName sec, name, lk, off)
  | sec <- ofSections obj
  , (name, lk, off) <- sectionSymbols sec
  ]

printRow :: (T.Text, T.Text, Linkage, Int) -> IO ()
printRow (sec, name, lk, off) =
  putStrLn $ printf "%04o %c %s" (off :: Int) (kindLetter sec lk) (T.unpack name)

kindLetter :: T.Text -> Linkage -> Char
kindLetter _ LkExtern = 'U'
kindLetter sec lk =
  let base = case T.unpack sec of
        "text" -> 't'
        "rodata" -> 'r'
        "data" -> 'd'
        "bss" -> 'b'
        _ -> '?'
   in if lk == LkLocal then base else upcase base
  where
    upcase c
      | c >= 'a' && c <= 'z' = toEnum (fromEnum c - 32)
      | otherwise = c

parseArgs :: [String] -> Maybe Mode
parseArgs ("--dump-syms" : path : rest)
  | null rest = Just (ModeDumpSyms path)
  | otherwise = Nothing
parseArgs xs = goAsm Nothing Nothing [] M.empty Nothing False xs
  where
    goAsm src out incs defs mFmt list [] =
      case src of
        Nothing -> Nothing
        Just s -> Just (ModeAssemble s out (reverse incs) defs mFmt list)
    goAsm src _out incs defs mFmt list ("-o" : p : ys) =
      goAsm src (Just p) incs defs mFmt list ys
    goAsm src _out incs defs mFmt list ("--output" : p : ys) =
      goAsm src (Just p) incs defs mFmt list ys
    goAsm src out incs defs mFmt list ("-I" : d : ys) =
      goAsm src out (d : incs) defs mFmt list ys
    goAsm src out incs defs mFmt list ("-D" : kv : ys) =
      case span (/= '=') kv of
        (k, '=' : v)
          | not (null k) ->
              goAsm src out incs (M.insert (T.pack k) (T.pack v) defs) mFmt list ys
        _ -> Nothing
    goAsm src out incs defs _ list ("--format" : f : ys)
      | f `elem` ["bin", "readmemb"] = goAsm src out incs defs (Just f) list ys
      | otherwise = Nothing
    goAsm src out incs defs mFmt _ ("--list" : ys) =
      goAsm src out incs defs mFmt True ys
    goAsm _ _ _ _ _ _ (x : _)
      | "-" `isPrefixOf` x = Nothing
    goAsm Nothing out incs defs mFmt list (x : ys) =
      goAsm (Just x) out incs defs mFmt list ys
    goAsm (Just _) _ _ _ _ _ (_ : _) = Nothing
