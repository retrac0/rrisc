module Main (main) where

import Data.List (isPrefixOf)
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (replaceExtension, takeExtension)
import System.IO (hPutStrLn, stderr)

import RRISC.Asm

usage :: String
usage =
  "Usage: hsasm source.s [-o output.bin] [-I dir]... [--format bin|readmemb] [--list]"

main :: IO ()
main = do
  args <- getArgs
  case parseArgs args of
    Nothing -> hPutStrLn stderr usage >> exitFailure
    Just (src, mOut, incDirs, fmt, doList) -> do
      eAsm <- assembleFile src incDirs
      case eAsm of
        Left err -> TIO.hPutStrLn stderr (formatAsmError err) >> exitFailure
        Right res -> do
          let defExt = if fmt == "readmemb" then ".mem" else ".bin"
              outPath = case mOut of
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

parseArgs :: [String] -> Maybe (FilePath, Maybe FilePath, [FilePath], String, Bool)
parseArgs xs = go Nothing Nothing [] "bin" False xs
  where
    go src out incs fmt list [] =
      case src of
        Nothing -> Nothing
        Just s -> Just (s, out, reverse incs, fmt, list)
    go src out incs fmt list ("-o" : p : xs') = go src (Just p) incs fmt list xs'
    go src out incs fmt list ("--output" : p : xs') = go src (Just p) incs fmt list xs'
    go src out incs fmt list ("-I" : d : xs') = go src out (d : incs) fmt list xs'
    go src out incs _ list ("--format" : f : xs')
      | f `elem` ["bin", "readmemb"] = go src out incs f list xs'
      | otherwise = Nothing
    go src out incs fmt _ ("--list" : xs') = go src out incs fmt True xs'
    go _ _ _ _ _ (x : _)
      | "-" `isPrefixOf` x = Nothing
    go Nothing out incs fmt list (x : xs') = go (Just x) out incs fmt list xs'
    go (Just _) _ _ _ _ (_ : _) = Nothing
