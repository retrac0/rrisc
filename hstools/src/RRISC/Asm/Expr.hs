{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm.Expr (evalExpr) where

import Control.Monad (when)
import Data.Bits ((.&.), (.|.), complement, shiftL, shiftR, xor)
import Data.Char (isAlphaNum, isDigit, isSpace)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Map.Strict as M
import RRISC.Asm.Types (AsmError (..))

evalExpr :: Text -> M.Map Text Int -> FilePath -> Int -> Either AsmError Int
evalExpr src labels fp ln = do
  when (T.null (T.strip src)) $ Left $ AsmError fp ln "empty expression"
  let t = T.strip src
  case parseOr t labels fp ln 0 of
    Left e -> Left e
    Right (v, pos) ->
      let rest = T.drop pos t
       in if T.null rest
            then Right v
            else Left $ AsmError fp ln $
              "in '" <> src <> "': unexpected '" <> rest <> "'"

type Parser = Text -> M.Map Text Int -> FilePath -> Int -> Int -> Either AsmError (Int, Int)

skipWs :: Text -> Int -> Int
skipWs t i = go i
  where
    go j
      | j >= T.length t = j
      | isSpace (T.index t j) = go (j + 1)
      | otherwise = j

xorI :: Int -> Int -> Int
xorI x y = fromIntegral (fromIntegral x `xor` (fromIntegral y :: Word))

shl :: Int -> Int -> Int
shl a b = shiftL a (max 0 (min 31 b))

shr :: Int -> Int -> Int
shr a b = shiftR a (max 0 (min 31 b))

parseOr :: Parser
parseOr t m fp ln i0 = do
  (v, i) <- parseXor t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j < T.length t && T.index t j == '|'
              then do
                (r, k) <- parseXor t m fp ln (j + 1)
                loop (vA .|. r) k
              else Right (vA, j)
  loop v i

parseXor :: Parser
parseXor t m fp ln i0 = do
  (v, i) <- parseAnd t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j < T.length t && T.index t j == '^'
              then do
                (r, k) <- parseAnd t m fp ln (j + 1)
                loop (xorI vA r) k
              else Right (vA, j)
  loop v i

parseAnd :: Parser
parseAnd t m fp ln i0 = do
  (v, i) <- parseShift t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j < T.length t && T.index t j == '&'
              then do
                (r, k) <- parseShift t m fp ln (j + 1)
                loop (vA .&. r) k
              else Right (vA, j)
  loop v i

parseShift :: Parser
parseShift t m fp ln i0 = do
  (v, i) <- parseAdd t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j + 1 < T.length t
              then
                let c0 = T.index t j; c1 = T.index t (j + 1)
                 in if c0 == '<' && c1 == '<'
                      then do
                        (r, k) <- parseAdd t m fp ln (j + 2)
                        loop (shl vA r) k
                      else
                        if c0 == '>' && c1 == '>'
                          then do
                            (r, k) <- parseAdd t m fp ln (j + 2)
                            loop (shr vA r) k
                          else Right (vA, j)
              else Right (vA, j)
  loop v i

parseAdd :: Parser
parseAdd t m fp ln i0 = do
  (v, i) <- parseMul t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j < T.length t
              then case T.index t j of
                '+' -> do
                  (r, k) <- parseMul t m fp ln (j + 1)
                  loop (vA + r) k
                '-' -> do
                  (r, k) <- parseMul t m fp ln (j + 1)
                  loop (vA - r) k
                _ -> Right (vA, j)
              else Right (vA, j)
  loop v i

parseMul :: Parser
parseMul t m fp ln i0 = do
  (v, i) <- parseUnary t m fp ln i0
  let loop vA iA =
        let j = skipWs t iA
         in if j < T.length t
              then
                let twoSlash =
                      j + 1 < T.length t
                        && T.index t j == '/'
                        && T.index t (j + 1) == '/'
                    c = T.index t j
                    opLen
                      | twoSlash = Just ("//", 2 :: Int)
                      | c == '/' = Just ("/", 1)
                      | c == '*' = Just ("*", 1)
                      | c == '%' = Just ("%", 1)
                      | otherwise = Nothing
                 in case opLen of
                      Nothing -> Right (vA, j)
                      Just (opStr, olen) -> do
                        (r, k) <- parseUnary t m fp ln (j + olen)
                        case opStr of
                          "*" -> loop (vA * r) k
                          "%" ->
                            if r == 0
                              then Left $ AsmError fp ln $ "in '" <> t <> "': division by zero"
                              else loop (vA `mod` r) k
                          "/" ->
                            if r == 0
                              then Left $ AsmError fp ln $ "in '" <> t <> "': division by zero"
                              else loop (vA `div` r) k
                          "//" ->
                            if r == 0
                              then Left $ AsmError fp ln $ "in '" <> t <> "': division by zero"
                              else loop (vA `div` r) k
                          _ -> Right (vA, j)
              else Right (vA, j)
  loop v i

parseUnary :: Parser
parseUnary t m fp ln i0 =
  let j = skipWs t i0
   in if j >= T.length t
        then Left $ AsmError fp ln $ "in '" <> t <> "': unexpected end of expression"
        else case T.index t j of
          '-' -> do
            (v, k) <- parseUnary t m fp ln (j + 1)
            Right (-v, k)
          '+' -> parseUnary t m fp ln (j + 1)
          '~' -> do
            (v, k) <- parseUnary t m fp ln (j + 1)
            Right (complement v .&. 0o7777, k)
          _ -> parseAtom t m fp ln j

parseAtom :: Parser
parseAtom t m fp ln i =
  let j = skipWs t i
   in if j >= T.length t
        then Left $ AsmError fp ln $ "in '" <> t <> "': unexpected end of expression"
        else
          let c = T.index t j
           in if c == '('
                then do
                  (v, k) <- parseOr t m fp ln (j + 1)
                  let k' = skipWs t k
                   in if k' >= T.length t || T.index t k' /= ')'
                        then Left $ AsmError fp ln $ "in '" <> t <> "': expected ')'"
                        else Right (v, k' + 1)
                else
                  if isDigit c
                    then readNumber t fp ln j
                    else
                      if isLabelStart c
                        then readLabel t m fp ln j
                        else Left $ AsmError fp ln $ "in '" <> t <> "': unexpected '" <> T.singleton c <> "'"

isLabelStart :: Char -> Bool
isLabelStart c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'

isLabelCont :: Char -> Bool
isLabelCont c = isAlphaNum c || c == '_'

readLabel :: Text -> M.Map Text Int -> FilePath -> Int -> Int -> Either AsmError (Int, Int)
readLabel t m fp ln i =
  let name = T.takeWhile isLabelCont (T.drop i t)
      k = i + T.length name
   in case M.lookup name m of
        Nothing -> Left $ AsmError fp ln $ "in '" <> t <> "': undefined label '" <> name <> "'"
        Just v -> Right (v, k)

readNumber :: Text -> FilePath -> Int -> Int -> Either AsmError (Int, Int)
readNumber t fp ln i =
  let tok = T.takeWhile (\c -> isAlphaNum c || c == '_') (T.drop i t)
   in case readIntTok tok fp ln t of
        Left e -> Left e
        Right v -> Right (v, i + T.length tok)

readIntTok :: Text -> FilePath -> Int -> Text -> Either AsmError Int
readIntTok tok fp ln full
  | T.null tok = Left $ AsmError fp ln $ "in '" <> full <> "': invalid number ''"
  | T.length tok >= 3 =
      let p1 = T.index tok 1
       in if (p1 == 'x' || p1 == 'X' || p1 == 'o' || p1 == 'O' || p1 == 'b' || p1 == 'B')
            then parsePrefixed tok fp ln full
            else if T.index tok 0 == '0' && T.length tok > 1
                  then parseOct tok fp ln full
                  else parseDec tok fp ln full
  | T.index tok 0 == '0' && T.length tok > 1 = parseOct tok fp ln full
  | otherwise = parseDec tok fp ln full

parsePrefixed :: Text -> FilePath -> Int -> Text -> Either AsmError Int
parsePrefixed tok fp ln full =
  case T.unpack (T.toLower (T.drop 2 tok)) of
    "" -> Left $ AsmError fp ln $ "in '" <> full <> "': invalid number '" <> tok <> "'"
    s ->
      let lc = T.index (T.toLower tok) 1
          base = case lc of
            'x' -> 16
            'o' -> 8
            'b' -> 2
            _ -> 16
       in case readBase base s of
            Nothing -> Left $ AsmError fp ln $ "in '" <> full <> "': invalid number '" <> tok <> "'"
            Just v -> Right v

parseOct :: Text -> FilePath -> Int -> Text -> Either AsmError Int
parseOct tok fp ln full =
  case T.unpack (T.drop 1 tok) of
    s
      | any (\c -> c < '0' || c > '7') s ->
          Left $ AsmError fp ln $ "in '" <> full <> "': invalid number '" <> tok <> "'"
      | otherwise ->
          Right $ foldl (\a c -> a * 8 + fromEnum c - fromEnum '0') 0 s

parseDec :: Text -> FilePath -> Int -> Text -> Either AsmError Int
parseDec tok fp ln full =
  case reads (T.unpack tok) of
    [(v, "")] -> Right v
    _ -> Left $ AsmError fp ln $ "in '" <> full <> "': invalid number '" <> tok <> "'"

readBase :: Int -> String -> Maybe Int
readBase 16 s = go 0 s
  where
    go acc "" = Just acc
    go acc (c : cs)
      | c >= '0' && c <= '9' = go (acc * 16 + fromEnum c - fromEnum '0') cs
      | c >= 'a' && c <= 'f' = go (acc * 16 + 10 + fromEnum c - fromEnum 'a') cs
      | c >= 'A' && c <= 'F' = go (acc * 16 + 10 + fromEnum c - fromEnum 'A') cs
      | otherwise = Nothing
readBase 8 s = go8 s 0
  where
    go8 "" acc = Just acc
    go8 (c : cs) acc
      | c >= '0' && c <= '7' = go8 cs (acc * 8 + fromEnum c - fromEnum '0')
      | otherwise = Nothing
readBase 2 s = go2 s 0
  where
    go2 "" acc = Just acc
    go2 (c : cs) acc
      | c == '0' || c == '1' = go2 cs (acc * 2 + fromEnum c - fromEnum '0')
      | otherwise = Nothing
readBase _ _ = Nothing
