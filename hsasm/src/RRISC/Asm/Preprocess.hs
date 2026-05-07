{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm.Preprocess (
  stripComment,
  parseStringLiteral,
  tokenizeLine,
  expandIncludes,
  collectMacroDefs,
  expandMacros,
  stripLines,
  collectDefines,
  filterConditionals,
  substitute,
  resolvePath,
) where

import Control.Exception (IOException, try)
import System.IO.Error (isDoesNotExistError)
import Control.Monad (foldM)
import Data.List (foldl')
import Data.Char (isAlphaNum, isDigit, isSpace)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.Map.Strict as M
import System.Directory (doesPathExist, getCurrentDirectory)
import System.FilePath (isAbsolute, normalise, takeDirectory, (</>))

import RRISC.Asm.Expr (evalExpr)
import RRISC.Asm.Types

stripComment :: Text -> Text
stripComment t = T.pack (go False (T.unpack t))
  where
    go _ "" = ""
    go inStr ('"' : cs) = '"' : go (not inStr) cs
    go False (';' : _) = ""
    go inStr (c : cs) = c : go inStr cs

resolvePath :: FilePath -> IO FilePath
resolvePath p =
  if isAbsolute p
    then return (normalise p)
    else do
      cwd <- getCurrentDirectory
      return (normalise (cwd </> p))

parseStringLiteral :: Text -> FilePath -> Int -> Either AsmError String
parseStringLiteral s fp ln =
  let t = T.strip s
   in if T.length t < 2 || T.index t 0 /= '"' || T.index t (T.length t - 1) /= '"'
        then Left $ AsmError fp ln "expected a quoted string literal"
        else go (T.unpack (T.take (T.length t - 2) (T.tail t)))
  where
    go "" = Right ""
    go ('\\' : c : cs)
      | c == 'n' = ('\n' :) <$> go cs
      | c == '\\' = ('\\' :) <$> go cs
      | otherwise = Left $ AsmError fp ln $ "unknown escape '\\" <> T.singleton c <> "'"
    go (c : cs) = (c :) <$> go cs

tokenizeLine :: FilePath -> Int -> Text -> Int -> Maybe Stmt
tokenizeLine fp ln raw si =
  let line = T.strip raw
   in if T.null line
        then Nothing
        else peel [] line
  where
    peel labels l =
      case T.uncons l of
        Nothing -> finish labels ""
        Just (c, _)
          | isLabelStart c ->
              let (name, afterName) = T.span isLabelCont l
               in case T.uncons afterName of
                    Just (':', rest) -> peel (labels ++ [name]) (T.strip rest)
                    _ -> finish labels l
          | otherwise -> finish labels l
    finish labels l =
      if T.null l
        then Just $ Stmt fp ln labels "" "" 0 si
        else
          let (mnem, rest) = T.break isSpace l
              ops = T.strip (T.dropWhile isSpace rest)
           in Just $ Stmt fp ln labels mnem ops 0 si

isLabelStart :: Char -> Bool
isLabelStart c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'

isLabelCont :: Char -> Bool
isLabelCont c = isAlphaNum c || c == '_'

isMacroNameChar :: Char -> Bool
isMacroNameChar c = isAlphaNum c || c == '_'

expandIncludes ::
  Text ->
  Maybe FilePath ->
  Set FilePath ->
  [FilePath] ->
  IO (Either AsmError [RawLine])
expandIncludes source mSrcPath seen incDirs =
  go mSrcPath seen source
  where
    go mPath seen0 src = do
      absPath <- case mPath of
        Nothing -> return Nothing
        Just p -> Just <$> resolvePath p
      let srcDir = maybe "" takeDirectory absPath
          seen1 = maybe seen0 (\p -> Set.insert p seen0) absPath
      foldM
        (processLine absPath srcDir seen1)
        (Right [])
        (zip [1 ..] (T.lines src))

    processLine absPath srcDir seen1 acc (lineno, raw) = case acc of
      Left e -> return (Left e)
      Right accLines -> do
        let line = T.strip (stripComment raw)
        case parseInclude line of
          Nothing -> return $ Right (accLines ++ [RawLine (maybe "" id absPath) lineno raw])
          Just incRel -> do
            let rl = RawLine (maybe "" id absPath) lineno raw
            pathToOpen <- pickIncludePath srcDir (T.unpack incRel) incDirs
            incResolved <- resolvePath pathToOpen
            if Set.member incResolved seen1
              then
                return $
                  Left $
                    AsmError (maybe "" id absPath) lineno $
                      "circular %include of '" <> incRel <> "'"
              else do
                eInner <- try (TIO.readFile pathToOpen)
                case eInner of
                  Left (e :: IOException) ->
                    let pyMsg =
                          if isDoesNotExistError e
                            then
                              "[Errno 2] No such file or directory: '"
                                <> T.pack pathToOpen
                                <> "'"
                            else T.pack (show e)
                     in return $
                          Left $
                            AsmError (maybe "" id absPath) lineno $
                              "cannot open included file '" <> incRel <> "': " <> pyMsg
                  Right inner -> do
                    sub <- go (Just pathToOpen) (Set.insert incResolved seen1) inner
                    case sub of
                      Left err -> return (Left err)
                      Right subLines -> return $ Right (accLines ++ [rl] ++ subLines)

pickIncludePath :: FilePath -> FilePath -> [FilePath] -> IO FilePath
pickIncludePath srcDir rel incDirs =
  if isAbsolute rel
    then normalise <$> resolvePath rel
    else do
      let candidate = normalise (srcDir </> rel)
      ok <- doesPathExist candidate
      if ok
        then return candidate
        else tryDirs candidate incDirs
  where
    tryDirs fallback [] = return fallback
    tryDirs _fallback (d : ds) = do
      let alt = normalise (d </> rel)
      ok <- doesPathExist alt
      if ok then return alt else tryDirs _fallback ds

parseInclude :: Text -> Maybe Text
parseInclude line =
  let l = T.strip line
   in if not ("%include" `T.isPrefixOf` l)
        then Nothing
        else
          let rest = T.strip (T.drop (T.length "%include") l)
           in case T.uncons rest of
                Just ('"', _) ->
                  let inner = T.tail rest
                      (path, after) = T.break (== '"') inner
                   in if T.null after || T.strip (T.tail after) /= ""
                        then Nothing
                        else Just path
                _ -> Nothing

collectMacroDefs :: [RawLine] -> Either AsmError ([RawLine], M.Map Text MacroDef)
collectMacroDefs = go [] M.empty
  where
    go acc mt [] = Right (acc, mt)
    go acc mt (rl : rls) =
      let line = T.strip (stripComment (rlText rl))
       in if "%macro" `T.isPrefixOf` line
            then parseMacro acc mt rl rls line
            else
              if line == "%endm"
                then Left $ AsmError (rlPath rl) (rlLineNo rl) "unexpected %endm without matching %macro"
                else go (acc ++ [rl]) mt rls

    parseMacro acc mt defRl rls line =
      let after' = T.strip (T.drop (T.length "%macro") line)
       in case T.uncons after' of
            Nothing -> Left $ AsmError (rlPath defRl) (rlLineNo defRl) "malformed %macro directive"
            Just (c, _)
              | not (isMacroNameChar c) ->
                  Left $ AsmError (rlPath defRl) (rlLineNo defRl) "malformed %macro directive"
              | otherwise ->
                  let (name, rest0) = T.span isMacroNameChar after'
                      paramsStr = T.strip rest0
                   in if M.member name mt
                        then Left $ AsmError (rlPath defRl) (rlLineNo defRl) $ "redefinition of macro '" <> name <> "'"
                        else
                          case parseMacroParams (rlPath defRl) (rlLineNo defRl) name paramsStr of
                            Left e -> Left e
                            Right params -> scanBody acc mt defRl rls name params

    parseMacroParams fp ln name ps
      | not (T.null ps) && T.all isDigit ps =
          Right [T.pack ('%' : show i) | i <- [1 .. read (T.unpack ps) :: Int]]
      | T.null ps = Right []
      | otherwise =
          let parts = map T.strip (T.splitOn "," ps)
           in traverse
                ( \p ->
                    if T.null p || not (isLabelStart (T.index p 0)) || not (T.all isMacroNameChar p)
                      then Left $ AsmError fp ln $ "invalid parameter name '" <> p <> "' in %macro " <> name
                      else Right p
                )
                parts

    scanBody acc mt defRl rls name params =
      let defPath = rlPath defRl
          defLn = rlLineNo defRl
          walk !bodyAcc !outAcc [] =
            Left $ AsmError defPath defLn $ "unterminated %macro '" <> name <> "': missing %endm"
          walk bodyAcc outAcc (brl : brls') =
            let bline = T.strip (stripComment (rlText brl))
             in if "%macro" `T.isPrefixOf` bline
                  then Left $ AsmError (rlPath brl) (rlLineNo brl) "nested %macro definition is not allowed"
                  else
                    if bline == "%endm"
                      then
                        let mdef = MacroDef params bodyAcc defPath defLn
                         in go (acc ++ outAcc ++ [brl]) (M.insert name mdef mt) brls'
                      else walk (bodyAcc ++ [brl]) (outAcc ++ [brl]) brls'
       in walk [] [defRl] rls

expandMacros :: [RawLine] -> M.Map Text MacroDef -> Set Text -> Either AsmError [RawLine]
expandMacros rlines macroTable expanding = go rlines
  where
    go [] = Right []
    go (rl : rls) =
      let line = T.strip (stripComment (rlText rl))
       in if T.null line
            then (rl :) <$> go rls
            else case tokenizeLine (rlPath rl) (rlLineNo rl) line 0 of
                  Nothing -> (rl :) <$> go rls
                  Just stmt ->
                    case M.lookup (stMnem stmt) macroTable of
                      Nothing -> (rl :) <$> go rls
                      Just mdef ->
                        if stMnem stmt `Set.member` expanding
                          then Left $ AsmError (rlPath rl) (rlLineNo rl) $ "recursive macro expansion of '" <> stMnem stmt <> "'"
                          else
                            let args = splitArgs (stOps stmt)
                             in if length args /= length (mdParams mdef)
                                  then
                                    Left $
                                      AsmError (rlPath rl) (rlLineNo rl) $
                                        "macro '" <> stMnem stmt <> "' expects "
                                          <> T.pack (show (length (mdParams mdef)))
                                          <> " argument(s), got "
                                          <> T.pack (show (length args))
                                  else
                                    let labelPrefix =
                                          if null (stLabels stmt)
                                            then ""
                                            else T.unwords (map (`T.snoc` ':') (stLabels stmt)) <> " "
                                        subst = zip (mdParams mdef) args
                                        comment = RawLine (rlPath rl) (rlLineNo rl) ("; %expand " <> line)
                                        expandedBody = expandMacroBody mdef labelPrefix subst
                                     in do
                                          mid <- expandMacros expandedBody macroTable (Set.insert (stMnem stmt) expanding)
                                          rest <- go rls
                                          Right (comment : mid ++ rest)

splitArgs :: Text -> [Text]
splitArgs ops
  | T.null (T.strip ops) = []
  | otherwise = map T.strip (T.splitOn "," ops)

expandMacroBody :: MacroDef -> Text -> [(Text, Text)] -> [RawLine]
expandMacroBody mdef labelPrefix subst = go True (mdBody mdef)
  where
    go _ [] = []
    go firstNonEmpty (brl : brls) =
      let bline = T.strip (stripComment (rlText brl))
       in if T.null bline
            then brl : go firstNonEmpty brls
            else
              let expanded = applySubst subst bline
                  expanded' =
                    if firstNonEmpty && labelPrefix /= ""
                      then labelPrefix <> " " <> expanded
                      else expanded
                  nl = RawLine (mdPath mdef) (rlLineNo brl) expanded'
               in nl : go False brls

applySubst :: [(Text, Text)] -> Text -> Text
applySubst pairs t = foldl (\acc (param, arg) -> subst1 param arg acc) t pairs
  where
    subst1 param arg txt
      | T.null param = txt
      | T.head param == '%' && T.all isDigit (T.tail param) = replacePosParam param arg txt
      | otherwise = replaceWholeWord param arg txt

replacePosParam :: Text -> Text -> Text -> Text
replacePosParam needle repl hay
  | T.null needle = hay
  | otherwise = go hay
  where
    nlen = T.length needle
    go s
      | T.null s = ""
      | needle `T.isPrefixOf` s =
          let after = T.drop nlen s
           in if not (T.null after) && isDigit (T.index after 0)
                then T.take 1 s <> go (T.tail s)
                else repl <> go after
      | otherwise = T.take 1 s <> go (T.tail s)

replaceWholeWord :: Text -> Text -> Text -> Text
replaceWholeWord needle repl hay
  | T.null needle = hay
  | otherwise = T.concat (go 0)
  where
    n = T.length needle
    hl = T.length hay
    isW c = isAlphaNum c || c == '_'
    wordMatch i =
      i + n <= hl
        && T.take n (T.drop i hay) == needle
        && (i == 0 || not (isW (T.index hay (i - 1))))
        && (i + n == hl || not (isW (T.index hay (i + n))))
    go i
      | i >= hl = []
      | wordMatch i = repl : go (i + n)
      | otherwise = T.singleton (T.index hay i) : go (i + 1)

stripLines :: [RawLine] -> [SourceLine]
stripLines rawLines = go False (zip [0 ..] rawLines)
  where
    go _ [] = []
    go inMacro ((ix, rl) : rls) =
      let line = T.strip (stripComment (rlText rl))
       in if "%macro" `T.isPrefixOf` line
            then go True rls
            else
              if line == "%endm"
                then go False rls
                else
                  if inMacro
                    then go True rls
                    else
                      if "%include" `T.isPrefixOf` line
                        then go False rls
                        else
                          if T.null line
                            then go False rls
                            else SourceLine (rlPath rl) (rlLineNo rl) line ix : go False rls

collectDefines :: [SourceLine] -> ([SourceLine], M.Map Text Text)
collectDefines sls =
  let (kept, dm) = foldl' step ([], M.empty) sls
   in (reverse kept, dm)
  where
    step (out, dm) sl = case parseDefine (slText sl) of
      Just (name, val) -> (out, M.insert name val dm)
      Nothing -> (sl : out, dm)

parseDefine :: Text -> Maybe (Text, Text)
parseDefine t
  | "%define" `T.isPrefixOf` t =
      let rest = T.strip (T.drop (T.length "%define") t)
          (name, afterName) = T.span isMacroNameChar rest
          val = T.strip (T.dropWhile isSpace afterName)
       in if T.null name then Nothing else Just (name, val)
  | otherwise = Nothing

filterConditionals :: [SourceLine] -> M.Map Text Text -> Either AsmError [SourceLine]
filterConditionals slines defineTable = go [] [] slines
  where
    go out stack [] =
      case stack of
        [] -> Right (reverse out)
        (openFn, openLn, _) : _ ->
          Left $ AsmError openFn openLn "unterminated %ifdef/%ifeq/%ifneq: missing %endif"
    go out stack (sl : sls) =
      let line = slText sl
       in if "%ifdef" `T.isPrefixOf` line
            then case parseIfdef line of
                  Nothing -> Left $ AsmError (slPath sl) (slLineNo sl) "malformed %ifdef directive"
                  Just name ->
                    go out ((slPath sl, slLineNo sl, name `M.member` defineTable) : stack) sls
            else
              case parseIfCmp line of
                Just (directive, operands) ->
                  let operands' = substOperands operands
                      tokens = T.words operands'
                   in if length tokens /= 2
                        then
                          Left $
                            AsmError (slPath sl) (slLineNo sl) $
                              directive <> " requires exactly 2 operands, got " <> T.pack (show (length tokens))
                        else
                          case ( evalExpr (tokens !! 0) M.empty (slPath sl) (slLineNo sl),
                                 evalExpr (tokens !! 1) M.empty (slPath sl) (slLineNo sl)
                               ) of
                            (Right a, Right b) ->
                              let ok =
                                    if directive == "%ifeq"
                                      then a == b
                                      else a /= b
                               in go out ((slPath sl, slLineNo sl, ok) : stack) sls
                            (Left e, _) -> Left e
                            (_, Left e) -> Left e
                Nothing ->
                  if T.strip line == "%endif"
                    then case stack of
                      [] -> Left $ AsmError (slPath sl) (slLineNo sl) "%endif without matching %ifdef/%ifeq/%ifneq"
                      _ : st -> go out st sls
                    else
                      if all (\(_, _, active) -> active) stack
                        then go (sl : out) stack sls
                        else go out stack sls
      where
        substOperands ops = foldl (\acc (k, v) -> replaceWholeWord k v acc) ops (M.toList defineTable)

parseIfCmp :: Text -> Maybe (Text, Text)
parseIfCmp line
  | "%ifeq" `T.isPrefixOf` line =
      Just ("%ifeq", T.strip (T.drop (T.length "%ifeq") line))
  | "%ifneq" `T.isPrefixOf` line =
      Just ("%ifneq", T.strip (T.drop (T.length "%ifneq") line))
  | otherwise = Nothing

parseIfdef :: Text -> Maybe Text
parseIfdef line =
  let rest0 = T.strip (T.drop (T.length "%ifdef") line)
      (name, trail) = T.span isMacroNameChar rest0
   in if T.null name
        then Nothing
        else
          if T.all isSpace trail then Just name else Nothing

substitute :: [SourceLine] -> M.Map Text Text -> [SourceLine]
substitute sls dm = map go sls
  where
    go sl =
      let t = foldl (\acc (k, v) -> replaceWholeWord k v acc) (slText sl) (M.toList dm)
       in sl {slText = t}
