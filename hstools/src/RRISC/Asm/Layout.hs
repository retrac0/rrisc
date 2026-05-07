{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm.Layout (
  assignAddresses,
  relaxBranches,
  stmtSize,
  labelsFromStmts,
  recomputeStmtAddrs,
  isSimpleLabel,
) where

import Control.Monad (foldM, when)
import Data.Char (isAlphaNum)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Map.Strict as M
import Data.Word (Word8)

import RRISC.Asm.Expr (evalExpr)
import RRISC.Asm.Preprocess (parseStringLiteral, tokenizeLine)
import RRISC.Asm.Types
import RRISC.ISA (wordMask)

import qualified Data.ByteString as BS

stringToUtf8' :: String -> [Word8]
stringToUtf8' = BS.unpack . TE.encodeUtf8 . T.pack

assignAddresses :: [SourceLine] -> Either AsmError ([Stmt], M.Map Text Int)
assignAddresses sls = go 0 [] M.empty sls
  where
    go !addr stmts labels [] = Right (stmts, labels)
    go !addr stmts labels (sl : rest) =
      case tokenizeLine (slPath sl) (slLineNo sl) (slText sl) (slSourceIx sl) of
        Nothing -> go addr stmts labels rest
        Just stmt0 ->
          let stmt = stmt0 {stAddr = addr}
           in do
                labels' <- foldM (addLabel (slPath sl) (slLineNo sl) addr) labels (stLabels stmt)
                if T.null (stMnem stmt)
                  then go addr (stmts ++ [stmt]) labels' rest
                  else
                    if stMnem stmt == ".org"
                      then do
                        when (T.null (T.strip (stOps stmt))) $
                          Left $
                            AsmError (slPath sl) (slLineNo sl) ".org requires an address"
                        newAddr <-
                          evalExpr (stOps stmt) labels' (slPath sl) (slLineNo sl)
                        if newAddr < 0 || newAddr > wordMask
                          then
                            Left $
                              AsmError (slPath sl) (slLineNo sl) $
                                ".org address " <> T.pack (show newAddr) <> " out of range (0..4095)"
                          else go newAddr stmts labels' rest
                      else
                        if stMnem stmt == ".align"
                          then do
                            if T.null (T.strip (stOps stmt))
                              then Left $ AsmError (slPath sl) (slLineNo sl) ".align requires an argument"
                              else do
                                a <- evalExpr (T.strip (stOps stmt)) labels' (slPath sl) (slLineNo sl)
                                if a < 1
                                  then
                                    Left $
                                      AsmError (slPath sl) (slLineNo sl) $
                                        ".align argument " <> T.pack (show a) <> " must be >= 1"
                                  else
                                    let newAddr = (addr + a - 1) `div` a * a
                                     in go newAddr (stmts ++ [stmt]) labels' rest
                          else do
                            d <- delta (stMnem stmt) (stOps stmt) labels' (slPath sl) (slLineNo sl)
                            go (addr + d) (stmts ++ [stmt]) labels' rest

    addLabel fp ln addr m l =
      if M.member l m
        then Left $ AsmError fp ln $ "duplicate label '" <> l <> "'"
        else Right (M.insert l addr m)

delta :: Text -> Text -> M.Map Text Int -> FilePath -> Int -> Either AsmError Int
delta mnem ops labels fp ln =
  case T.unpack mnem of
    "li" -> Right 2
    ".word" -> Right $ max 1 (length (splitComma ops))
    ".float" -> Right $ max 1 (length (splitComma ops)) * 4
    ".sixbit" -> do
      s <- parseStringLiteral ops fp ln
      Right $ length s
    ".unicode" -> do
      s <- parseStringLiteral ops fp ln
      Right $ length (stringToUtf8' s)
    ".fill" ->
      let countStr = T.strip $ fst $ T.break (== ',') ops
       in if T.null countStr
            then Left $ AsmError fp ln ".fill requires a count"
            else do
              c <- evalExpr countStr labels fp ln
              if c < 0
                then Left $ AsmError fp ln $ ".fill count " <> T.pack (show c) <> " must be non-negative"
                else Right c
    ".base" -> Left $ AsmError fp ln "'.base' is not supported by this assembler"
    "jmp" -> Right 3
    "call" -> Right 3
    "or" -> Right 3
    "xor" -> Right 4
    _ -> Right 1

splitComma :: Text -> [Text]
splitComma t
  | T.null (T.strip t) = []
  | otherwise = map T.strip (T.splitOn "," t)

relaxBranches :: [Stmt] -> Either AsmError ([Stmt], M.Map Text Int)
relaxBranches stmts0 = go 0 stmts0
  where
    go !n stmts =
      let labels = labelsFromStmts stmts
          violations =
            [ i
            | (i, s) <- zip [0 ..] stmts,
              stMnem s == "bt" || stMnem s == "bf",
              let o = T.strip (stOps s),
              isSimpleLabel o,
              Just t <- [M.lookup o labels],
              let off = t - stAddr s,
              off < -64 || off > 63
            ]
       in if null violations
            then Right (stmts, labels)
            else
              let i = maximum violations
                  stmt = stmts !! i
                  target = T.strip (stOps stmt)
                  skipLbl = "__br_" <> T.pack (show n)
                  inv = if stMnem stmt == "bt" then "bf" else "bt"
                  f = stPath stmt
                  ln = stLine stmt
                  si = stSourceIx stmt
                  replacement =
                    [ Stmt f ln [] inv skipLbl (-1) si,
                      Stmt f ln [] "li" ("r4, " <> target) (-1) si,
                      Stmt f ln [] "jalr" "r0, r4" (-1) si,
                      Stmt f ln [skipLbl] "" "" (-1) si
                    ]
                  stmts' = take i stmts ++ replacement ++ drop (i + 1) stmts
               in go (n + 1) (recomputeStmtAddrs stmts')

labelsFromStmts :: [Stmt] -> M.Map Text Int
labelsFromStmts = foldl addLabels M.empty
  where
    addLabels m s = foldl (\m' l -> M.insert l (stAddr s) m') m (stLabels s)

-- After branch relaxation: preserve forward address gaps from '.org' / alignment.
-- Using abs (orig - running) > 100 missed .org 0o100 (64 words); match asm.py.
recomputeStmtAddrs :: [Stmt] -> [Stmt]
recomputeStmtAddrs stmts = snd $ mapAccumL step 0 stmts
  where
    step !running stmt =
      let addr =
            if stAddr stmt /= -1 && stAddr stmt > running
              then stAddr stmt
              else running
          sz = stmtSize stmt
       in (addr + sz, stmt {stAddr = addr})

mapAccumL :: (acc -> x -> (acc, y)) -> acc -> [x] -> (acc, [y])
mapAccumL f z xs = go z xs
  where
    go a [] = (a, [])
    go a (x : xs') =
      let (a', y) = f a x
          (a'', ys) = go a' xs'
       in (a'', y : ys)

stmtSize :: Stmt -> Int
stmtSize stmt =
  let mnem = stMnem stmt
      ops = stOps stmt
      f = stPath stmt
      n = stLine stmt
   in case T.unpack mnem of
        "" -> 0
        ".align" -> 0
        "li" -> 2
        ".word" -> max 1 (length (splitComma ops))
        ".float" -> max 1 (length (splitComma ops)) * 4
        ".sixbit" ->
          case parseStringLiteral ops f n of
            Left _ -> 0
            Right s -> length s
        ".unicode" ->
          case parseStringLiteral ops f n of
            Left _ -> 0
            Right s -> length (stringToUtf8' s)
        ".fill" ->
          let countStr = T.strip $ fst $ T.break (== ',') ops
           in if T.null countStr
                then 0
                else case evalExpr countStr M.empty f n of
                  Left _ -> 0
                  Right c -> max 0 c
        "jmp" -> 3
        "call" -> 3
        "or" -> 3
        "xor" -> 4
        _ -> 1

isSimpleLabel :: Text -> Bool
isSimpleLabel t
  | T.null t = False
  | otherwise =
      let c0 = T.index t 0
       in (isAlpha c0 || c0 == '_') && T.all isLabelChar t
  where
    isAlpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
    isLabelChar c = isAlphaNum c || c == '_'
