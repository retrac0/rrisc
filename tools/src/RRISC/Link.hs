{-# LANGUAGE OverloadedStrings #-}
-- | RRISC linker.
--
--   Reads relocatable objects, places sections at absolute addresses, runs a
--   fixed-point branch-relaxation pass over each section's 'brel' records,
--   resolves symbols, and emits a flat 12-bit word stream plus a map file.
--
--   Cross-object resolution: a symbol assembled as @LkLocal@ in one object
--   can satisfy an undefined reference from another object when that name has
--   exactly one definition address across the whole link (otherwise duplicate).
--
--   Reloc records are applied during final emission via 'patchPlaceholders'.
module RRISC.Link (
  LinkOptions (..),
  defaultLinkOptions,
  LinkResult (..),
  PlacedSymbol (..),
  PlacedSection (..),
  LinkError (..),
  formatLinkError,
  linkObjectFiles,
  linkFiles,
  renderMap,
) where

import Control.Monad (foldM, when)
import Data.Bits (shiftL, shiftR, xor, (.&.), (.|.))
import Data.Char (intToDigit)
import Data.List (foldl', nub, sortBy)
import Data.Ord (comparing)
import qualified Data.IntSet as IS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Map.Strict as M
import Numeric (showIntAtBase)

import RRISC.ISA
  ( addiOp, encodeR3, encodeRI, imm6Mask, jalrRb, luiOp, specOp, wordMask )
import RRISC.Obj.Format

-- | For each section name, indices of ItemBrel that were grown to the 4-word
-- trampoline. Indices are section-local (per merged item list). A single
-- 'IntSet' across all sections was wrong: text and data could both have a
-- branch at index @i@, and relaxing one would incorrectly relax the other.
type RelaxedBrels = M.Map Text IS.IntSet

------------------------------------------------------------
-- Options / results / errors
------------------------------------------------------------

data LinkOptions = LinkOptions
  { -- | Pinned section bases.  Default: @[("text", 0)]@ — matches legacy
    --   behaviour because step-3 objects bake the .org prelude into the
    --   section as leading 'zero' records.
    loSectionBases :: ![(Text, Int)]
  } deriving (Show)

defaultLinkOptions :: LinkOptions
defaultLinkOptions = LinkOptions { loSectionBases = [("text", 0)] }

data PlacedSymbol = PlacedSymbol
  { psName :: !Text
  , psObject :: !FilePath
  , psSection :: !Text
  , psLinkage :: !Linkage
  , psAddr :: !Int
  } deriving (Show)

data PlacedSection = PlacedSection
  { plSecName :: !Text
  , plSecBase :: !Int
  , plSecSize :: !Int
  } deriving (Show)

data LinkResult = LinkResult
  { lrWords :: ![Int]
  , lrSymbols :: ![PlacedSymbol]
  , lrSections :: ![PlacedSection]
  , lrInputs :: ![FilePath]
  } deriving (Show)

data LinkError
  = LinkParseError ObjParseError
  | LinkUnsupported FilePath !Text
  | LinkAddressOutOfRange FilePath !Text !Int
  | LinkUndefinedSymbol !Text
  | LinkDuplicateSymbol !Text !Int !Int
  | LinkBranchOutOfRange !Text !Int   -- shouldn't happen post-relaxation
  | LinkRelaxConvergence !Text       -- shouldn't happen
  deriving (Show)

formatLinkError :: LinkError -> Text
formatLinkError (LinkParseError e) = formatObjParseError e
formatLinkError (LinkUnsupported fp msg) =
  T.pack fp <> ": " <> msg
formatLinkError (LinkAddressOutOfRange fp sec addr) =
  T.pack fp <> ": section '" <> sec
    <> "' word at " <> showOct addr <> " exceeds 12-bit address space"
formatLinkError (LinkUndefinedSymbol sym) =
  "undefined reference to '" <> sym <> "'"
formatLinkError (LinkDuplicateSymbol sym a b) =
  "duplicate definition of '" <> sym <> "' at 0o" <> showOct a <> " and 0o" <> showOct b
formatLinkError (LinkBranchOutOfRange sym off) =
  "branch to '" <> sym <> "' offset " <> tshow off
    <> " out of range after relaxation (internal error)"
formatLinkError (LinkRelaxConvergence sym) =
  "branch relaxation failed to converge near symbol '" <> sym <> "'"

linkFiles :: LinkOptions -> [FilePath] -> IO (Either LinkError LinkResult)
linkFiles opts paths = do
  loaded <- mapM readObjectFile paths
  case sequence loaded of
    Left e -> return (Left (LinkParseError e))
    Right objs -> return (linkObjectFiles opts (zip paths objs))

------------------------------------------------------------
-- Internal item stream
------------------------------------------------------------

-- | A section's records flattened into placement units.  Sym/Loc are
--   zero-size; Word is one word; Brel is one or four depending on relax;
--   Reloc bundles the N placeholder words it patches into one fixed-size
--   item (so symbol shifting from relaxation can't desync the reloc from
--   its words).
data Item
  = ItemWord !Int
  | ItemBrel !FilePath !BranchKind !Text !Int
  | ItemReloc !FilePath !RelocKind ![Int] !Text !Int
  | ItemSym !FilePath !Text !Linkage !(Maybe Int)
  | ItemLoc !FilePath !Int
  deriving Show

-- | Same-named sections from multiple inputs are concatenated in input
--   order.  Each chunk remembers its source path for diagnostics.
data SectionPiece = SectionPiece
  { spSource :: !FilePath
  , spName :: !Text
  , spItems :: ![Item]
  } deriving Show

-- | Walk records left-to-right and bundle each 'reloc' with its preceding
--   N word items.  Sym/Loc are not allowed to interleave between the
--   placeholder words and their reloc (the assembler emits them
--   contiguously).  Other records pass through.
recordsToItems :: FilePath -> [SecRecord] -> Either LinkError [Item]
recordsToItems src = go []
  where
    go acc [] = Right (reverse acc)
    go acc (r : rs) = case r of
      RecWord w -> go (ItemWord w : acc) rs
      RecZero n -> go (replicate (max 0 n) (ItemWord 0) ++ acc) rs
      RecSym n lk mo -> go (ItemSym src n lk mo : acc) rs
      RecLoc fp ln -> go (ItemLoc fp ln : acc) rs
      RecBrel bk sym addend -> go (ItemBrel src bk sym addend : acc) rs
      RecReloc kind sym addend -> do
        let n = relocSpan kind
        case popPlaceholders n acc [] of
          Left e -> Left e
          Right (ws, rest) ->
            go (ItemReloc src kind ws sym addend : rest) rs

    popPlaceholders 0 rest collected = Right (reverse collected, rest)
    popPlaceholders k (ItemWord w : rest) collected =
      popPlaceholders (k - 1) rest (w : collected)
    popPlaceholders _ _ _ =
      Left (LinkUnsupported src "'reloc' record must follow N word records (no sym/loc/brel between them)")

relocSpan :: RelocKind -> Int
relocSpan RkImm12 = 1
relocSpan RkLiImm12 = 2
relocSpan RkJmpTarget12 = 3
relocSpan RkCallTarget12 = 3
relocSpan RkImm6Pc = 1

------------------------------------------------------------
-- Top-level linking
------------------------------------------------------------

linkObjectFiles
  :: LinkOptions
  -> [(FilePath, ObjectFile)]
  -> Either LinkError LinkResult
linkObjectFiles opts inputs = do
  pieces <- sequence
    [ do its <- recordsToItems fp (secRecords sec)
         Right (SectionPiece fp (secName sec) its)
    | (fp, obj) <- inputs
    , sec <- ofSections obj
    ]

  let addPiece acc p =
        let key = spName p
            cur = M.findWithDefault [] key acc
         in M.insert key (cur ++ [p]) acc
      -- Concatenate same-named sections in input order.
      bySection = foldl' addPiece M.empty pieces
      secOrder = collectSectionOrder pieces
      bases = assignBases opts secOrder

  -- Build a per-section item list (concatenated across pieces, with piece
  -- boundaries noted).  After this point we work per section.
  let merged =
        [ (nm, concatMap spItems (M.findWithDefault [] nm bySection))
        | nm <- secOrder
        ]

  -- Initial relax state: all brels unrelaxed (per section).
  let initRelaxed = M.empty

  -- Fixed-point loop over relaxation flips.  Each iteration computes
  -- per-item offsets for every section, then derives the global symbol
  -- map, then walks every brel and decides whether it must relax.
  finalRelaxed <- relaxLoop merged bases initRelaxed (length pieces * 4 + 16)

  -- Final layout from the converged relax state.
  let finalLayouts =
        [ (nm, layoutSection (M.findWithDefault IS.empty nm finalRelaxed) items, items)
        | (nm, items) <- merged
        ]
      symbols = collectPlacedSymbols bases finalLayouts
  symEnv <- buildSymbolEnv bases finalLayouts

  -- Emit per-section words at absolute addresses.
  emitted <- mapM (emitSection bases finalRelaxed symEnv) finalLayouts

  let placedSections =
        [ PlacedSection nm (sectionBase bases nm) sz
        | (nm, layout, _) <- finalLayouts
        , let sz = lyTotal layout
        ]
      flatPairs = concat emitted
      maxAddr = if null flatPairs then -1 else maximum (map fst flatPairs)
      img =
        if maxAddr < 0
          then []
          else
            let zeros = replicate (maxAddr + 1) 0
             in foldl (\xs (a, w) -> setAt xs a (w .&. wordMask)) zeros flatPairs

  -- Final 12-bit address-space sanity check.
  case [(secNameOf nm, a) | (a, _) <- flatPairs, a > wordMask, let nm = ()]
       ++ [(nm, plSecBase s + plSecSize s - 1)
          | s <- placedSections
          , let nm = plSecName s
          , plSecSize s > 0
          , plSecBase s + plSecSize s - 1 > wordMask
          ] of
    [] -> Right ()
    ((nm, addr) : _) ->
      Left (LinkAddressOutOfRange (firstInputFor inputs) nm addr)

  Right $ LinkResult
    { lrWords = img
    , lrSymbols = symbols
    , lrSections = placedSections
    , lrInputs = map fst inputs
    }
  where
    secNameOf = const "(unknown)" :: () -> Text
    firstInputFor [] = "<no inputs>"
    firstInputFor ((fp, _) : _) = fp

------------------------------------------------------------
-- Section placement
------------------------------------------------------------

collectSectionOrder :: [SectionPiece] -> [Text]
collectSectionOrder = go []
  where
    go acc [] = reverse acc
    go acc (p : ps)
      | spName p `elem` acc = go acc ps
      | otherwise = go (spName p : acc) ps

assignBases :: LinkOptions -> [Text] -> [(Text, Int)]
assignBases opts secOrder =
  let pinned = loSectionBases opts
      unpinned = filter (\n -> n `notElem` map fst pinned) secOrder
   in pinned ++ map (\n -> (n, 0)) unpinned

sectionBase :: [(Text, Int)] -> Text -> Int
sectionBase bases nm = M.findWithDefault 0 nm (M.fromList bases)

------------------------------------------------------------
-- Per-section layout (offsets per item, total size)
------------------------------------------------------------

data Layout = Layout
  { lyOffsets :: ![Int]   -- one offset per item (cumulative pre-size)
  , lyTotal :: !Int
  } deriving Show

itemSize :: IS.IntSet -> Int -> Item -> Int
itemSize relaxed idx it = case it of
  ItemWord _ -> 1
  ItemBrel{} -> if IS.member idx relaxed then 4 else 1
  ItemReloc _ kind _ _ _ -> relocSpan kind
  ItemSym{} -> 0
  ItemLoc{} -> 0

layoutSection :: IS.IntSet -> [Item] -> Layout
layoutSection relaxed items =
  let sizes = zipWith (\i it -> itemSize relaxed i it) [0..] items
      offs = scanl (+) 0 sizes
   in Layout
        { lyOffsets = init offs   -- one offset per item
        , lyTotal = last offs
        }

------------------------------------------------------------
-- Symbol resolution (C-like: object-local vs global)
------------------------------------------------------------

data SymbolEnv = SymbolEnv
  { seGlobal :: !(M.Map Text Int)
  , seLocal :: !(M.Map (FilePath, Text) Int)
  -- | Names that appear as @LkLocal@ in exactly one place (one address) across
  --   all objects.  Used to resolve references from another object to a label
  --   that was assembled as file-local (e.g. @__fcopy@ from an @%include@ in
  --   one TU while a second TU calls it without defining it).
  , seUniqueLocalName :: !(M.Map Text Int)
  }
  deriving (Show)

-- | Symbols placed for map output (locals and globals; not @LkExtern@ stubs).
collectPlacedSymbols
  :: [(Text, Int)]
  -> [(Text, Layout, [Item])]
  -> [PlacedSymbol]
collectPlacedSymbols bases sections =
  [ PlacedSymbol name objFp secnm lk addr
  | (secnm, layout, items) <- sections
  , (idx, ItemSym objFp name lk mo) <- zip [0..] items
  , lk /= LkExtern
  , let base = sectionBase bases secnm
        addr = case mo of
          Just o -> base + o
          Nothing -> base + (lyOffsets layout !! idx)
  ]

-- | One address per name for @LkLocal@ definitions that appear across objects.
--   If the same name is defined locally in two places at different addresses,
--   linking fails with 'LinkDuplicateSymbol'.
uniqueLocalNamesFromSections
  :: [(Text, Int)]
  -> [(Text, Layout, [Item])]
  -> Either LinkError (M.Map Text Int)
uniqueLocalNamesFromSections bases sections =
  M.traverseWithKey unify grouped
  where
    pairs :: [(Text, Int)]
    pairs =
      concat
        [ [ (name, addr)
          | (idx, ItemSym _objFp name lk mo) <- zip [0 :: Int ..] items
          , lk == LkLocal
          , let base = sectionBase bases secnm
                addr =
                  case mo of
                    Just o -> base + o
                    Nothing -> base + (lyOffsets layout !! idx)
          ]
        | (secnm, layout, items) <- sections
        ]
    grouped :: M.Map Text [Int]
    grouped = foldl' (\m (n, a) -> M.insertWith (++) n [a] m) M.empty pairs
    unify :: Text -> [Int] -> Either LinkError Int
    unify name addrs =
      case nub addrs of
        [a] -> Right a
        (a : b : _) -> Left (LinkDuplicateSymbol name a b)
        [] -> Left (LinkUnsupported "" ("internal: empty local sym list for " <> name))

-- | Merge global definitions (visible across objects) and per-object locals.
buildSymbolEnv
  :: [(Text, Int)]
  -> [(Text, Layout, [Item])]
  -> Either LinkError SymbolEnv
buildSymbolEnv bases sections = do
  env <- foldM mergeSection (SymbolEnv M.empty M.empty M.empty) sections
  ulns <- uniqueLocalNamesFromSections bases sections
  pure (env {seUniqueLocalName = ulns})
  where
    mergeSection env (secnm, layout, items) =
      foldM (mergeItem secnm layout) env (zip [0 :: Int ..] items)

    mergeItem secnm layout env (idx, it) = case it of
      ItemSym objFp name lk mo
        | lk == LkExtern -> Right env
        | otherwise ->
            let base = sectionBase bases secnm
                addr = case mo of
                  Just o -> base + o
                  Nothing -> base + (lyOffsets layout !! idx)
             in case lk of
                  LkLocal ->
                    Right env {seLocal = M.insert (objFp, name) addr (seLocal env)}
                  LkGlobal -> insertG name addr env
                  LkWeak -> insertG name addr env
                  LkExtern -> Right env
      _ -> Right env

    insertG name addr env = case M.lookup name (seGlobal env) of
      Just prev
        | prev /= addr -> Left (LinkDuplicateSymbol name prev addr)
      _ -> Right $ env {seGlobal = M.insert name addr (seGlobal env)}

resolveSym :: FilePath -> Text -> SymbolEnv -> Either LinkError Int
resolveSym objFp name env =
  case M.lookup (objFp, name) (seLocal env) of
    Just a -> Right a
    Nothing -> case M.lookup name (seGlobal env) of
      Just a -> Right a
      Nothing -> case M.lookup name (seUniqueLocalName env) of
        Just a -> Right a
        Nothing -> Left (LinkUndefinedSymbol name)

------------------------------------------------------------
-- Fixed-point relaxation
------------------------------------------------------------

relaxLoop
  :: [(Text, [Item])]
  -> [(Text, Int)]
  -> RelaxedBrels
  -> Int   -- iteration budget
  -> Either LinkError RelaxedBrels
relaxLoop merged bases relaxed budget
  | budget <= 0 =
      Left (LinkRelaxConvergence "(budget exhausted)")
  | otherwise = do
      let layouts =
            [ (nm, layoutSection (M.findWithDefault IS.empty nm relaxed) its, its)
            | (nm, its) <- merged
            ]
      symEnv <- buildSymbolEnv bases layouts
      (relaxed', changed) <- foldM (relaxOne bases symEnv) (relaxed, False) layouts
      if changed
        then relaxLoop merged bases relaxed' (budget - 1)
        else Right relaxed

relaxOne
  :: [(Text, Int)]
  -> SymbolEnv
  -> (RelaxedBrels, Bool)
  -> (Text, Layout, [Item])
  -> Either LinkError (RelaxedBrels, Bool)
relaxOne bases symEnv (relaxed, changed) (nm, layout, items) = do
  let base = sectionBase bases nm
      secRel0 = M.findWithDefault IS.empty nm relaxed
      pairs = zip3 [0..] items (lyOffsets layout)
  (secRel1, ch1) <- foldM (step base) (secRel0, False) pairs
  let relaxed' = M.insert nm secRel1 relaxed
  return (relaxed', changed || ch1)
  where
    step base (rs, ch) (idx, ItemBrel fp _bk sym addend, off)
      | IS.member idx rs = Right (rs, ch)
      | otherwise = do
          target <- resolveSym fp sym symEnv
          let branchAddr = base + off
              offset = (target + addend) - branchAddr
          if offset < -64 || offset > 63
            then Right (IS.insert idx rs, True)
            else Right (rs, ch)
    step _ acc _ = Right acc

------------------------------------------------------------
-- Word emission per section
------------------------------------------------------------

emitSection
  :: [(Text, Int)]
  -> RelaxedBrels
  -> SymbolEnv
  -> (Text, Layout, [Item])
  -> Either LinkError [(Int, Int)]
emitSection bases relaxed symEnv (nm, layout, items) = do
  let base = sectionBase bases nm
      secRel = M.findWithDefault IS.empty nm relaxed
      pairs = zip3 [0..] items (lyOffsets layout)
  concat <$> mapM (emitItem base secRel symEnv) pairs

emitItem
  :: Int
  -> IS.IntSet
  -> SymbolEnv
  -> (Int, Item, Int)
  -> Either LinkError [(Int, Int)]
emitItem base _ _ (_, ItemWord w, off) =
  Right [(base + off, w .&. wordMask)]
emitItem _ _ _ (_, ItemSym{}, _) = Right []
emitItem _ _ _ (_, ItemLoc{}, _) = Right []
emitItem base _relaxed symEnv (_idx, ItemReloc fp kind ws sym addend, off) = do
  target <- resolveSym fp sym symEnv
  let val = target + addend
      branchAddr = base + off
  -- recordsToItems attaches reloc after placeholder words but pops newest-first;
  -- restore source order [lui, addi] / [lui, addi, jalr] before patching imm fields.
  patched <- patchPlaceholders kind (reverse ws) val branchAddr
  Right $
    [ (base + off + i, w .&. wordMask)
    | (i, w) <- zip [0 :: Int ..] patched
    ]
emitItem base secRel symEnv (idx, ItemBrel fp bk sym addend, off) = do
  target <- resolveSym fp sym symEnv
  let branchAddr = base + off
      offset = (target + addend) - branchAddr
      isRelaxed = IS.member idx secRel
  if not isRelaxed
    then do
      when (offset < -64 || offset > 63) $
        Left (LinkBranchOutOfRange sym offset)
      let rd = if offset < 0 then 7 else 0
          op = case bk of
            BkBt -> addiOp
            BkBf -> luiOp
      Right [(branchAddr, encodeRI op rd (offset .&. imm6Mask))]
    else do
      -- Relaxed sequence (4 words):
      --   inv_branch +4   ; skip the long-jump body
      --   lui  r4, hi6
      --   addi r4, lo6
      --   jalr r0, r4
      let invOp = case bk of
            BkBt -> luiOp   -- bf
            BkBf -> addiOp  -- bt
          tgt = (target + addend) .&. wordMask
          hi6 = (tgt `shiftR` 6) .&. imm6Mask
          lo6 = tgt .&. imm6Mask
      Right
        [ (branchAddr,     encodeRI invOp 0 4)
        , (branchAddr + 1, encodeRI luiOp 4 hi6)
        , (branchAddr + 2, encodeRI addiOp 4 lo6)
        , (branchAddr + 3, encodeR3 specOp 0 4 jalrRb)
        ]

------------------------------------------------------------
-- Reloc patching
------------------------------------------------------------

patchPlaceholders :: RelocKind -> [Int] -> Int -> Int -> Either LinkError [Int]
patchPlaceholders kind ws val branchAddr = case kind of
  RkImm12 -> Right [val .&. wordMask]
  RkLiImm12 -> case ws of
    [w0, w1] ->
      let masked = val .&. wordMask
          hi6 = (masked `shiftR` 6) .&. imm6Mask
          lo6 = masked .&. imm6Mask
       in Right [setImm6 w0 hi6, setImm6 w1 lo6]
    _ -> Left (LinkUnsupported "" "li-imm12 reloc must cover exactly 2 words")
  RkJmpTarget12 -> case ws of
    [w0, w1, w2] ->
      let masked = val .&. wordMask
          hi6 = (masked `shiftR` 6) .&. imm6Mask
          lo6 = masked .&. imm6Mask
       in Right [setImm6 w0 hi6, setImm6 w1 lo6, w2]
    _ -> Left (LinkUnsupported "" "jmp-target12 reloc must cover exactly 3 words")
  RkCallTarget12 -> case ws of
    [w0, w1, w2] ->
      let masked = val .&. wordMask
          hi6 = (masked `shiftR` 6) .&. imm6Mask
          lo6 = masked .&. imm6Mask
       in Right [setImm6 w0 hi6, setImm6 w1 lo6, w2]
    _ -> Left (LinkUnsupported "" "call-target12 reloc must cover exactly 3 words")
  RkImm6Pc -> case ws of
    [w0] ->
      let off = val - branchAddr
          rd = if off < 0 then 7 else 0
       in if off < -64 || off > 63
            then Left (LinkBranchOutOfRange "" off)
            else Right [setImm6 (setRd w0 rd) (off .&. imm6Mask)]
    _ -> Left (LinkUnsupported "" "imm6-pc reloc must cover exactly 1 word")

-- Replace the imm6 (low 6 bits) of an encoded R-I word.
setImm6 :: Int -> Int -> Int
setImm6 w v = (w .&. complement6) .|. (v .&. imm6Mask)
  where
    complement6 = (wordMask) `xor` imm6Mask

-- Replace the rd field (bits 6..8) of an encoded word.
setRd :: Int -> Int -> Int
setRd w rd = (w .&. complementRd) .|. ((rd .&. 7) `shiftL` 6)
  where
    complementRd = wordMask `xor` (7 `shiftL` 6)

------------------------------------------------------------
-- setAt (immutable list, O(n))
------------------------------------------------------------

setAt :: [a] -> Int -> a -> [a]
setAt xs i v = front ++ v : drop 1 back
  where
    (front, back) = splitAt i xs

------------------------------------------------------------
-- Map file
------------------------------------------------------------

renderMap :: LinkResult -> Text
renderMap lr = T.unlines $
  ["RRISC link map", ""]
    ++ ["Inputs:"]
    ++ map (("  " <>) . T.pack) (lrInputs lr)
    ++ [""]
    ++ ["Sections:"]
    ++ map renderSection (lrSections lr)
    ++ [""]
    ++ ["Symbols (sorted by address):"]
    ++ map renderSym (sortBy (comparing psAddr) (lrSymbols lr))
  where
    renderSection (PlacedSection nm base sz) =
      "  " <> padR 8 nm
        <> "  base=" <> showOct base
        <> "  size=" <> showOct sz
    renderSym (PlacedSymbol name obj sec lk addr) =
      "  " <> padR 20 name
        <> "  " <> padR 28 (T.pack obj)
        <> "  " <> showOct addr
        <> "  " <> padR 8 sec
        <> "  " <> renderLk lk
    renderLk LkLocal = "local"
    renderLk LkGlobal = "global"
    renderLk LkExtern = "extern"
    renderLk LkWeak = "weak"

padR :: Int -> Text -> Text
padR n t = t <> T.replicate (max 0 (n - T.length t)) " "

showOct :: Int -> Text
showOct n =
  let x = n .&. 0xFFFFFF
      s = showIntAtBase 8 intToDigit x ""
      s' = if null s then "0" else s
      pad = max 0 (4 - length s')
   in T.pack ("0o" ++ replicate pad '0' ++ s')

tshow :: Show a => a -> Text
tshow = T.pack . show
