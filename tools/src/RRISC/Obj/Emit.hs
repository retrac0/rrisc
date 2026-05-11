{-# LANGUAGE OverloadedStrings #-}
-- | Step-3 object emission.  Walks statements with their *pre-relaxation*
--   addresses and produces an ObjectFile where:
--
--     * Branches with a simple-label operand become 'brel' records (the
--       linker relaxes them).
--
--     * Instructions whose operand is a simple label (li / .word) emit
--       placeholder lui+addi words with rd already
--       encoded plus a 'reloc' record; the linker patches the imm6 fields
--       once final symbol addresses are known.  Without this, the
--       assembler would bake in *pre-relaxation* addresses that go stale
--       as soon as the linker grows any earlier branch.
--
--   Anything else (constants, expressions without labels) is encoded
--   normally with the in-TU label map.
module RRISC.Obj.Emit (
  encodeToObject,
) where

import Data.List (nub)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Map.Strict as M

import RRISC.Asm.Encode (encodeStmt, splitOps)
import RRISC.Asm.Layout (isSimpleLabel, labelsFromStmts, linkageMapFromStmts)
import RRISC.Asm.Types
import RRISC.ISA (addiOp, encodeRI, luiOp)
import RRISC.Obj.Format

encodeToObject
  :: [Stmt]
  -> [RawLine]
  -> Either AsmError ObjectFile
encodeToObject stmts raws = do
  let linkage = linkageMapFromStmts stmts
      bySec =
        foldl
          (\m st -> M.insertWith (flip (++)) (stSection st) [st] m)
          M.empty
          stmts
      secNames = nub (map stSection stmts)
  sectionList <-
    mapM
      ( \nm -> do
          let raw = M.findWithDefault [] nm bySec
              norm = normalizeSection raw
              labs = labelsFromStmts norm
          rs <- buildRecords norm labs linkage
          return (Section nm rs)
      )
      secNames
  Right $
    ObjectFile
      { ofVersion = objVersion
      , ofSources = nub (map rlPath raws)
      , ofSections = sectionList
      }

-- | Section-local address base 0 for object records (linker provides absolute base).
normalizeSection :: [Stmt] -> [Stmt]
normalizeSection [] = []
normalizeSection ss =
  let b = minimum (map stAddr ss)
   in map (\s -> s {stAddr = stAddr s - b}) ss

buildRecords :: [Stmt] -> M.Map Text Int -> M.Map Text Linkage -> Either AsmError [SecRecord]
buildRecords stmts labels linkage = go 0 Nothing [] stmts
  where
    go _ _ acc [] = Right (reverse acc)
    go !cursor curLoc acc (st : rest) = do
      let target = stAddr st
          gap = target - cursor
          gapRecs = [RecZero gap | gap > 0]
          symRecs =
            [ RecSym l (M.findWithDefault LkLocal l linkage) Nothing
            | l <- stLabels st
            ]
          loc = (stPath st, stLine st)
          (locRecs, curLoc') =
            if T.null (stMnem st) || curLoc == Just loc
              then ([], curLoc)
              else ([RecLoc (fst loc) (snd loc)], Just loc)
      (instrRecs, advance) <- emitStmt st labels linkage
      let acc' = reverse instrRecs
                  ++ reverse locRecs
                  ++ reverse symRecs
                  ++ reverse gapRecs
                  ++ acc
      go (target + advance) curLoc' acc' rest

emitStmt :: Stmt -> M.Map Text Int -> M.Map Text Linkage -> Either AsmError ([SecRecord], Int)
emitStmt st labels _ =
  let mnem = T.toLower (stMnem st)
      ops = splitOps (stOps st)
      fp = stPath st
      ln = stLine st
   in case (mnem, ops) of
        (".global", _) -> Right ([], 0)
        (".globl", _) -> Right ([], 0)
        (".local", _) -> Right ([], 0)
        (".section", _) -> Right ([], 0)
        ("bt", [op]) | isSimpleLabel (T.strip op) ->
          Right ([RecBrel BkBt (T.strip op) 0], 1)
        ("bf", [op]) | isSimpleLabel (T.strip op) ->
          Right ([RecBrel BkBf (T.strip op) 0], 1)
        ("li", [rdTok, vTok])
          | isSimpleLabel (T.strip vTok) ->
              case parseReg fp ln rdTok of
                Right rd ->
                  let recs =
                        [ RecWord (encodeRI luiOp rd 0)
                        , RecWord (encodeRI addiOp rd 0)
                        , RecReloc RkLiImm12 (T.strip vTok) 0
                        ]
                   in Right (recs, 2)
                Left _ -> fallback
        (".word", _) ->
          encodeDotWord ops fp ln labels
        _ -> fallback
  where
    fallback = do
      ws <- encodeStmt st labels
      Right (map RecWord ws, length ws)

-- | .word can take multiple operands; each is either a simple label
--   (linker reloc) or a constant expression (resolved here).
encodeDotWord
  :: [Text]
  -> FilePath
  -> Int
  -> M.Map Text Int
  -> Either AsmError ([SecRecord], Int)
encodeDotWord ops fp ln labels =
  if any isSimpleLabel (map T.strip ops)
    then do
      recs <- concat <$> mapM oneWord ops
      Right (recs, length ops)
    else do
      ws <- encodeStmtRaw fp ln labels ops
      Right (map RecWord ws, length ws)
  where
    oneWord raw =
      let v = T.strip raw
       in if isSimpleLabel v
            then Right [RecWord 0, RecReloc RkImm12 v 0]
            else do
              ws <- encodeStmtRaw fp ln labels [raw]
              Right (map RecWord ws)

-- | Tiny helper: re-enter the legacy encoder for a synthetic .word stmt.
encodeStmtRaw
  :: FilePath
  -> Int
  -> M.Map Text Int
  -> [Text]
  -> Either AsmError [Int]
encodeStmtRaw fp ln labels ops =
  let synthetic = Stmt
        { stPath = fp
        , stLine = ln
        , stLabels = []
        , stMnem = ".word"
        , stOps = T.intercalate ", " ops
        , stAddr = 0
        , stSourceIx = 0
        , stSection = "text"
        }
   in encodeStmt synthetic labels

parseReg :: FilePath -> Int -> Text -> Either AsmError Int
parseReg fp ln s =
  let t = T.strip s
   in case T.unpack t of
        ['r', d]
          | d >= '0' && d <= '7' -> Right (fromEnum d - fromEnum '0')
        _ -> Left $ AsmError fp ln $ "invalid register '" <> t <> "'"
