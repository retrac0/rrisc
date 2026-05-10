{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Control.Monad (when)
import Data.List (isPrefixOf)
import Data.Version (showVersion)
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (replaceExtension, takeExtension)
import System.IO (hPutStrLn, stderr)

import Paths_rrisc_tools (version)

import RRISC.Asm (writeBinary, writeReadmemb)
import RRISC.Link

usage :: String
usage =
  unlines
    [ "Usage: rld input.o [input2.o ...] [-o output] [--format bin|readmemb]"
    , "             [--map output.map] [--code-base <addr>] [--data-base <addr>]"
    , "  -V, --version         print version and exit"
    ]

data Args = Args
  { aInputs :: [FilePath]
  , aOutput :: Maybe FilePath
  , aFormat :: String
  , aMap :: Maybe FilePath
  , aCodeBase :: Maybe Int
  , aDataBase :: Maybe Int
  }

emptyArgs :: Args
emptyArgs = Args [] Nothing "bin" Nothing Nothing Nothing

main :: IO ()
main = do
  argv <- getArgs
  when (argv == ["--version"] || argv == ["-V"]) $ do
    putStrLn $ "rld " ++ showVersion version
    exitSuccess
  case parseArgs argv emptyArgs of
    Nothing -> hPutStrLn stderr usage >> exitFailure
    Just args -> run args

run :: Args -> IO ()
run args
  | null (aInputs args) = hPutStrLn stderr usage >> exitFailure
  | otherwise = do
      let bases =
            [("text", cb) | Just cb <- [aCodeBase args]]
              ++ [("data", db) | Just db <- [aDataBase args]]
          opts =
            if null bases
              then defaultLinkOptions
              else defaultLinkOptions {loSectionBases = bases}
      eRes <- linkFiles opts (aInputs args)
      case eRes of
        Left err -> TIO.hPutStrLn stderr (formatLinkError err) >> exitFailure
        Right res -> do
          let outPath = case aOutput args of
                Just p -> p
                Nothing -> deriveOutput (head (aInputs args)) (aFormat args)
          if aFormat args == "readmemb"
            then writeReadmemb outPath (lrWords res)
            else writeBinary outPath (lrWords res)
          case aMap args of
            Just mp -> TIO.writeFile mp (renderMap res)
            Nothing -> return ()
          exitSuccess

deriveOutput :: FilePath -> String -> FilePath
deriveOutput inp fmt =
  let ext = if fmt == "readmemb" then ".mem" else ".bin"
   in if null (takeExtension inp)
        then inp ++ ext
        else replaceExtension inp ext

parseArgs :: [String] -> Args -> Maybe Args
parseArgs [] acc = Just acc {aInputs = reverse (aInputs acc)}
parseArgs ("-o" : p : rest) acc =
  parseArgs rest acc {aOutput = Just p}
parseArgs ("--output" : p : rest) acc =
  parseArgs rest acc {aOutput = Just p}
parseArgs ("--format" : f : rest) acc
  | f `elem` ["bin", "readmemb"] = parseArgs rest acc {aFormat = f}
  | otherwise = Nothing
parseArgs ("--map" : p : rest) acc =
  parseArgs rest acc {aMap = Just p}
parseArgs ("--code-base" : v : rest) acc =
  case parseIntArg v of
    Just n -> parseArgs rest acc {aCodeBase = Just n}
    Nothing -> Nothing
parseArgs ("--data-base" : v : rest) acc =
  case parseIntArg v of
    Just n -> parseArgs rest acc {aDataBase = Just n}
    Nothing -> Nothing
parseArgs (x : _) _
  | "-" `isPrefixOf` x = Nothing
parseArgs (x : rest) acc =
  parseArgs rest acc {aInputs = x : aInputs acc}

parseIntArg :: String -> Maybe Int
parseIntArg s = case s of
  ('0' : 'o' : ds) | not (null ds) -> readBase 8 ds
  ('0' : 'O' : ds) | not (null ds) -> readBase 8 ds
  ('0' : 'x' : ds) | not (null ds) -> readBase 16 ds
  ('0' : 'X' : ds) | not (null ds) -> readBase 16 ds
  ('0' : 'b' : ds) | not (null ds) -> readBase 2 ds
  ('0' : 'B' : ds) | not (null ds) -> readBase 2 ds
  _ -> readsInt s
  where
    readsInt v = case reads v :: [(Int, String)] of
      [(n, "")] -> Just n
      _ -> Nothing

    readBase b ds = foldl1 step <$> traverse (val b) ds
      where
        step a d = a * b + d

    val b c
      | c >= '0' && c <= '9' && fromEnum c - fromEnum '0' < b =
          Just (fromEnum c - fromEnum '0')
      | c >= 'a' && c <= 'f' && b == 16 =
          Just (fromEnum c - fromEnum 'a' + 10)
      | c >= 'A' && c <= 'F' && b == 16 =
          Just (fromEnum c - fromEnum 'A' + 10)
      | otherwise = Nothing
