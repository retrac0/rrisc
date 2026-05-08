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

import Paths_hstools (version)

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
    [ "Usage: hsasm source.s [-o output] [-I dir]... [-D NAME=value]..."
    , "                      [--format bin|readmemb]"
    , "                      [--list] [--emit-obj] [--obj-out path]"
    , "                      [--obj-only] (emit relocatable .o only; no flat .bin)"
    , "       hsasm --dump-syms file.o"
    , "  -V, --version         print version and exit"
    ]

data Mode
  = ModeAssemble
      FilePath              -- src
      (Maybe FilePath)      -- explicit -o output (else derived from src + format)
      [FilePath]            -- include dirs
      (M.Map T.Text T.Text) -- %define overrides from -D (applied after file %defines)
      String                -- format ("bin" | "readmemb")
      Bool                  -- emit listing to stdout
      Bool                  -- emit .o alongside the binary
      (Maybe FilePath)      -- explicit --obj-out path
      Bool                  -- obj only: skip flat binary (for TU with unresolved externals)
  | ModeDumpSyms FilePath

main :: IO ()
main = do
  args <- getArgs
  when (args == ["--version"] || args == ["-V"]) $ do
    putStrLn $ "hsasm " ++ showVersion version
    exitSuccess
  case parseArgs args of
    Nothing -> hPutStrLn stderr usage >> exitFailure
    Just (ModeDumpSyms path) -> dumpSyms path
    Just m@ModeAssemble{} -> runAssemble m

runAssemble :: Mode -> IO ()
runAssemble ModeDumpSyms{} = error "unreachable"
runAssemble (ModeAssemble src outArg incDirs cliDefines fmt doList emitObj objOut objOnly) = do
  if objOnly
    then do
      eObj <- assembleFileToObject src incDirs cliDefines
      case eObj of
        Left err -> TIO.hPutStrLn stderr (formatAsmError err) >> exitFailure
        Right obj -> do
          let objPath = case objOut of
                Just p -> p
                Nothing -> case outArg of
                  Just p -> p
                  Nothing -> replaceExtension src ".o"
          writeObjectFile objPath obj
          exitSuccess
    else do
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
          if emitObj
            then do
              eObj <- assembleFileToObject src incDirs cliDefines
              case eObj of
                Left err -> TIO.hPutStrLn stderr (formatAsmError err) >> exitFailure
                Right obj -> do
                  let objPath = case objOut of
                        Just p -> p
                        Nothing -> replaceExtension outPath ".o"
                  writeObjectFile objPath obj
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

-- nm-style letter: section + linkage.  Uppercase = global, lowercase = local.
-- Extern (undefined) is always 'U' regardless of section.
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
parseArgs xs = goAsm Nothing Nothing [] M.empty "bin" False False Nothing False xs
  where
    goAsm src out incs defs fmt list emit objOut objOnly [] =
      case src of
        Nothing -> Nothing
        Just s -> Just (ModeAssemble s out (reverse incs) defs fmt list emit objOut objOnly)
    goAsm src _out incs defs fmt list emit objOut objOnly ("-o" : p : ys) =
      goAsm src (Just p) incs defs fmt list emit objOut objOnly ys
    goAsm src _out incs defs fmt list emit objOut objOnly ("--output" : p : ys) =
      goAsm src (Just p) incs defs fmt list emit objOut objOnly ys
    goAsm src out incs defs fmt list emit objOut objOnly ("-I" : d : ys) =
      goAsm src out (d : incs) defs fmt list emit objOut objOnly ys
    goAsm src out incs defs fmt list emit objOut objOnly ("-D" : kv : ys) =
      case span (/= '=') kv of
        (k, '=' : v)
          | not (null k) ->
              goAsm src out incs (M.insert (T.pack k) (T.pack v) defs) fmt list emit objOut objOnly ys
        _ -> Nothing
    goAsm src out incs defs _ list emit objOut objOnly ("--format" : f : ys)
      | f `elem` ["bin", "readmemb"] = goAsm src out incs defs f list emit objOut objOnly ys
      | otherwise = Nothing
    goAsm src out incs defs fmt _ emit objOut objOnly ("--list" : ys) =
      goAsm src out incs defs fmt True emit objOut objOnly ys
    goAsm src out incs defs fmt list _ objOut objOnly ("--emit-obj" : ys) =
      goAsm src out incs defs fmt list True objOut objOnly ys
    goAsm src out incs defs fmt list emit _ objOnly ("--obj-out" : p : ys) =
      goAsm src out incs defs fmt list emit (Just p) objOnly ys
    goAsm src out incs defs fmt list emit objOut _ ("--obj-only" : ys) =
      goAsm src out incs defs fmt list emit objOut True ys
    goAsm _ _ _ _ _ _ _ _ _objOnly (x : _)
      | "-" `isPrefixOf` x = Nothing
    goAsm Nothing out incs defs fmt list emit objOut objOnly (x : ys) =
      goAsm (Just x) out incs defs fmt list emit objOut objOnly ys
    goAsm (Just _) _ _ _ _ _ _ _ _ (_ : _) = Nothing
