{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm (
  assembleFile,
  AsmResult (..),
  formatListing,
  writeBinary,
  writeReadmemb,
  formatAsmError,
) where

import Data.Bits (shiftR, (.&.))
import Data.Char (intToDigit)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.Map.Strict as M
import Numeric (showIntAtBase)
import System.Directory (getCurrentDirectory)
import System.FilePath (makeRelative)
import Text.Printf (printf)

import qualified Data.ByteString.Builder as B
import qualified Data.ByteString.Lazy as BL
import RRISC.Asm.Encode (ListingEntry (..), encodeProgram)
import RRISC.Asm.Layout (assignAddresses, relaxBranches)
import RRISC.Asm.Preprocess (
  collectDefines,
  collectMacroDefs,
  expandIncludes,
  expandMacros,
  filterConditionals,
  resolvePath,
  stripLines,
  substitute,
 )
import RRISC.Asm.Types (AsmError, RawLine (..), formatAsmError)
import RRISC.ISA (wordMask)

data AsmResult = AsmResult
  { arWords :: [Int]
  , arFlatLines :: [RawLine]
  , arListing :: [ListingEntry]
  }

assembleFile :: FilePath -> [FilePath] -> IO (Either AsmError AsmResult)
assembleFile srcPath incDirs = do
  absPath <- resolvePath srcPath
  source <- TIO.readFile absPath
  seen0 <- Set.singleton <$> resolvePath absPath
  eraw <- expandIncludes source (Just absPath) seen0 incDirs
  case eraw of
    Left e -> return (Left e)
    Right raw0 -> return $ assembleFromRaw raw0

assembleFromRaw :: [RawLine] -> Either AsmError AsmResult
assembleFromRaw raw0 = do
  (raw1, macroTable) <- collectMacroDefs raw0
  raw2 <- expandMacros raw1 macroTable Set.empty
  let flat = raw2
      slines0 = stripLines flat
      (slines1, defines) = collectDefines slines0
  slines2 <- filterConditionals slines1 defines
  let slines3 = substitute slines2 defines
  (stmts0, _) <- assignAddresses slines3
  (stmts1, labels) <- relaxBranches stmts0
  (words1, listing) <- encodeProgram stmts1 labels
  Right $ AsmResult words1 flat listing

formatListing :: [RawLine] -> [ListingEntry] -> IO Text
formatListing flatLines entries = do
  cwd <- getCurrentDirectory
  let byLoc = foldr addEntry M.empty entries
      addEntry (ListingEntry lix addr w) m =
        M.insertWith (++) lix [(addr, w)] m
      fmtOct4 n =
        let s = showIntAtBase 8 intToDigit n ""
            s' = if null s then "0" else s
            pad = max 0 (4 - length s')
         in replicate pad '0' ++ s'
      go _prevFile seen [] _ = (seen, [] :: [Text])
      go prevFile seen (rl : rls) i =
        let fn = rlPath rl
            ln = rlLineNo rl
            raw = rlText rl
            (header, seen0, prev0) =
              if fn == prevFile
                then ("", seen, prevFile)
                else
                  let rel = T.pack (makeRelative cwd fn)
                      tag = if Set.member fn seen then " (continued)" else ""
                   in ("; ==== " <> rel <> tag <> " ====", Set.insert fn seen, fn)
            lnStr = T.pack (printf "%4d" ln)
            content =
              case M.lookup i byLoc of
                Nothing -> [lnStr <> "              " <> raw]
                Just [] -> [lnStr <> "              " <> raw]
                Just ((a0, w0) : rest) ->
                  ( lnStr <> "  " <> T.pack (fmtOct4 a0) <> "  " <> T.pack (fmtOct4 w0) <> "  " <> raw
                  )
                    : [T.pack $ "      " ++ fmtOct4 a ++ "  " ++ fmtOct4 w | (a, w) <- rest]
            block = if T.null header then content else (header : content)
            (seen1, restLines) = go prev0 seen0 rls (i + 1)
         in (seen1, block ++ restLines)
      (_, linesOut) = go "" Set.empty flatLines 0
  return $ T.intercalate "\n" linesOut

writeBinary :: FilePath -> [Int] -> IO ()
writeBinary path ws = BL.writeFile path (B.toLazyByteString (mconcat (map wordBuilder ws)))
  where
    wordBuilder w =
      let x = w .&. wordMask
       in B.word8 (fromIntegral (x .&. 0xFF)) <> B.word8 (fromIntegral ((x `shiftR` 8) .&. 0x0F))

writeReadmemb :: FilePath -> [Int] -> IO ()
writeReadmemb path ws = writeFile path (unlines [pad12 (w .&. wordMask) | w <- ws])
  where
    pad12 n =
      let s = showIntAtBase 2 intToDigit n ""
          s' = if null s then "0" else s
          pad = max 0 (12 - length s')
       in replicate pad '0' ++ s'
