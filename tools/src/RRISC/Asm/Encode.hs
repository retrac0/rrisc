{-# LANGUAGE OverloadedStrings #-}
module RRISC.Asm.Encode (
  encodeProgram,
  encodeStmt,
  splitOps,
  ListingEntry (..),
) where

import Control.Monad (when)
import Data.Bits (shiftR, (.&.))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Map.Strict as M
import qualified Data.ByteString as BS
import qualified Data.IntMap.Strict as IM

import RRISC.Asm.Expr (evalExpr)
import RRISC.Asm.Layout (isSimpleLabel)
import RRISC.Asm.Preprocess (parseStringLiteral)
import RRISC.Asm.Types
import RRISC.Float48 (fromFloat)
import RRISC.ISA
import RRISC.SixBit (encodeSixbit)

data ListingEntry = ListingEntry
  { leSourceIx :: !Int
  , leAddr :: !Int
  , leWord :: !Int
  }

encodeProgram :: [Stmt] -> M.Map Text Int -> Either AsmError ([Int], [ListingEntry])
encodeProgram stmts labels =
  go IM.empty [] stmts
  where
    go !im !es [] =
      let maxAddr = if IM.null im then -1 else fst (IM.findMax im)
          arr
            | maxAddr < 0 = []
            | otherwise = [IM.findWithDefault 0 a im | a <- [0 .. maxAddr]]
       in Right (arr, es)
    go im es (stmt : rest) = do
      ws <- encodeStmt stmt labels
      let addr = stAddr stmt
          wsM = zip [0 ..] ws
          im' = foldl (\m (i, w) -> IM.insert (addr + i) (w .&. wordMask) m) im wsM
          es' = es ++ [ListingEntry (stSourceIx stmt) (addr + i) (w .&. wordMask) | (i, w) <- wsM]
      go im' es' rest

encodeStmt :: Stmt -> M.Map Text Int -> Either AsmError [Int]
encodeStmt stmt labels =
  let mnem = stMnem stmt
      opsStr = stOps stmt
      ops = splitOps opsStr
      fp = stPath stmt
      ln = stLine stmt
      addr = stAddr stmt
   in if T.null mnem
        then Right []
        else encMnem mnem ops opsStr fp ln addr labels

encMnem :: Text -> [Text] -> Text -> FilePath -> Int -> Int -> M.Map Text Int -> Either AsmError [Int]
encMnem mnem ops opsStr fp ln addr labels =
  case T.unpack (T.toLower mnem) of
    "nop" -> op0 0o0000
    "clrt" -> op0 0o3000
    "halt" -> op0 0o7777
    ".word" -> encWord fp ln ops labels
    ".sixbit" -> encSixbit fp ln opsStr
    ".unicode" -> encUnicode fp ln opsStr
    ".float" -> encFloat fp ln ops
    ".fill" -> encFill fp ln ops labels
    ".align" -> encAlign addr fp ln ops labels
    "and" -> r3 andOp
    "add" -> r3 addOp
    "addc" -> r3 addcOp
    "sub" -> r3 subOp
    "lui" -> encLui fp ln ops labels
    "addi" -> encAddi fp ln ops labels
    "subi" -> encSubi fp ln ops labels
    "bf" -> encBranch luiOp fp ln addr ops labels
    "bt" -> encBranch addiOp fp ln addr ops labels
    "jalr" -> spec jalrRb
    "ror" -> spec rorRb
    "rol" -> spec rolRb
    "lwr" -> spec lwrRb
    "swr" -> spec swrRb
    "lw" ->
      Left $ AsmError fp ln "'lw' is not part of this ISA; use lwr/swr (register-addressed)"
    "sw" ->
      Left $ AsmError fp ln "'sw' is not part of this ISA; use lwr/swr (register-addressed)"
    "li" -> encLi fp ln ops labels
    "mov" -> do
      expectCount fp ln mnem ops 3
      rd <- reg fp ln (ops !! 0)
      ra <- reg fp ln (ops !! 1)
      rz <- reg fp ln (ops !! 2)
      Right [encodeR3 andOp rd ra rz]
    "clr" -> do
      expectCount fp ln mnem ops 1
      rd <- reg fp ln (ops !! 0)
      Right [encodeR3 andOp rd 0 0]
    "neg" -> do
      expectCount fp ln mnem ops 2
      rd <- reg fp ln (ops !! 0)
      rb <- reg fp ln (ops !! 1)
      Right [encodeR3 subOp rd 0 rb]
    "not" -> do
      expectCount fp ln mnem ops 2
      rd <- reg fp ln (ops !! 0)
      rb <- reg fp ln (ops !! 1)
      Right [encodeR3 subOp rd 7 rb]
    "ret" -> do
      expectCount fp ln mnem ops 0
      Right [encodeR3 specOp 0 5 jalrRb]
    "test" -> do
      expectCount fp ln mnem ops 1
      rb <- reg fp ln (ops !! 0)
      Right [encodeR3 subOp 0 0 rb]
    "set" -> do
      expectCount fp ln mnem ops 0
      Right [encodeR3 subOp 0 0 7]
    "jmp" -> encJmp fp ln ops labels
    "call" -> encCall fp ln ops labels
    "or" -> encOr fp ln ops
    "xor" -> encXor fp ln ops
    ".global" -> Right []
    ".globl" -> Right []
    ".local" -> Right []
    ".section" -> Right []
    _ -> Left $ AsmError fp ln $ "unknown mnemonic '" <> mnem <> "'"
  where
    op0 w = expectCount fp ln mnem ops 0 >> Right [w]
    r3 op = do
      expectCount fp ln mnem ops 3
      rd <- reg fp ln (ops !! 0)
      ra <- reg fp ln (ops !! 1)
      rb <- reg fp ln (ops !! 2)
      Right [encodeR3 op rd ra rb]
    spec rb = do
      expectCount fp ln mnem ops 2
      rd <- reg fp ln (ops !! 0)
      ra <- reg fp ln (ops !! 1)
      Right [encodeR3 specOp rd ra rb]

expectCount :: FilePath -> Int -> Text -> [Text] -> Int -> Either AsmError ()
expectCount fp ln mnem ops n =
  when (length ops /= n) $
    Left $
      AsmError fp ln $
        "'" <> mnem <> "' expects " <> T.pack (show n) <> " operand(s), got " <> T.pack (show (length ops))

splitOps :: Text -> [Text]
splitOps t
  | T.null (T.strip t) = []
  | otherwise = map T.strip (T.splitOn "," t)

reg :: FilePath -> Int -> Text -> Either AsmError Int
reg fp ln s =
  let t = T.strip s
   in case T.unpack t of
        ['r', d]
          | d >= '0' && d <= '7' ->
              Right (fromEnum d - fromEnum '0')
        _ -> Left $ AsmError fp ln $ "invalid register '" <> t <> "'"

imm6u :: FilePath -> Int -> Int -> Either AsmError Int
imm6u fp ln val =
  if val < 0 || val > 63
    then Left $ AsmError fp ln $ "immediate " <> T.pack (show val) <> " out of 6-bit unsigned range (0..63)"
    else Right (val .&. imm6Mask)

encWord :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encWord fp ln ops labels = do
  when (null ops) $ Left $ AsmError fp ln ".word requires a value"
  traverse (\v -> (.&. wordMask) <$> evalExpr v labels fp ln) ops

encSixbit :: FilePath -> Int -> Text -> Either AsmError [Int]
encSixbit fp ln opsStr = do
  s <- parseStringLiteral (T.strip opsStr) fp ln
  traverse
    ( \c -> case encodeSixbit c of
        Nothing -> Left $ AsmError fp ln $ "character " <> T.pack (show c) <> " has no SIXBIT representation"
        Just v -> Right v
    )
    s

encUnicode :: FilePath -> Int -> Text -> Either AsmError [Int]
encUnicode fp ln opsStr = do
  s <- parseStringLiteral (T.strip opsStr) fp ln
  let bs = BS.unpack (TE.encodeUtf8 (T.pack s))
  Right (map fromIntegral bs)

encFloat :: FilePath -> Int -> [Text] -> Either AsmError [Int]
encFloat fp ln ops = do
  when (null ops) $ Left $ AsmError fp ln ".float requires a value"
  concat <$> traverse (oneFloat fp ln) ops

oneFloat :: FilePath -> Int -> Text -> Either AsmError [Int]
oneFloat fp ln v =
  let v' = T.strip v
   in case reads (T.unpack v') of
        [(d :: Double, "")] -> Right (fromFloat d)
        _ -> Left $ AsmError fp ln $ "invalid float literal '" <> v' <> "'"

encFill :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encFill fp ln ops labels = do
  when (null ops) $ Left $ AsmError fp ln ".fill requires a count"
  when (length ops > 2) $ Left $ AsmError fp ln $ ".fill takes at most 2 operands, got " <> T.pack (show (length ops))
  count <- evalExpr (ops !! 0) labels fp ln
  when (count < 0) $ Left $ AsmError fp ln $ ".fill count " <> T.pack (show count) <> " must be non-negative"
  val <-
    if length ops > 1
      then (.&. wordMask) <$> evalExpr (ops !! 1) labels fp ln
      else Right 0
  Right (replicate count val)

encAlign :: Int -> FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encAlign addr fp ln ops labels = do
  when (null ops) $ Left $ AsmError fp ln ".align requires an argument"
  let opsStr = T.strip (head ops)
  when (T.null opsStr) $ Left $ AsmError fp ln ".align requires an argument"
  a <- evalExpr opsStr labels fp ln
  when (a < 1) $ Left $ AsmError fp ln $ ".align argument " <> T.pack (show a) <> " must be >= 1"
  let n = (- addr) `mod` a
  Right (replicate n 0)

encLui :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encLui fp ln ops labels = do
  expectCount fp ln "lui" ops 2
  rd <- reg fp ln (ops !! 0)
  when (rd == 0) $ Left $ AsmError fp ln "lui cannot target r0 (use bf for branches)"
  when (rd == 7) $ Left $ AsmError fp ln "lui cannot target r7 (use bf for branches)"
  v <- evalExpr (ops !! 1) labels fp ln >>= imm6u fp ln
  Right [encodeRI luiOp rd v]

encAddi :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encAddi fp ln ops labels = do
  expectCount fp ln "addi" ops 2
  rd <- reg fp ln (ops !! 0)
  when (rd == 0) $ Left $ AsmError fp ln "addi cannot target r0 (use bt for branches)"
  when (rd == 7) $ Left $ AsmError fp ln "addi cannot target r7 (use bt for branches)"
  v <- evalExpr (ops !! 1) labels fp ln >>= imm6u fp ln
  Right [encodeRI addiOp rd v]

encSubi :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encSubi fp ln ops labels = do
  expectCount fp ln "subi" ops 2
  rd <- reg fp ln (ops !! 0)
  when (rd == 0) $ Left $ AsmError fp ln "subi cannot target r0"
  when (rd == 7) $ Left $ AsmError fp ln "subi cannot target r7"
  v <- evalExpr (ops !! 1) labels fp ln >>= imm6u fp ln
  Right [encodeRI subiOp rd v]

encBranch :: Int -> FilePath -> Int -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encBranch op fp ln instrAddr ops labels = do
  expectCount fp ln (if op == luiOp then "bf" else "bt") ops 1
  off <- branchOperand (T.strip (head ops)) instrAddr fp ln labels
  let rd = if off < 0 then 7 else 0
  Right [encodeRI op rd (off .&. imm6Mask)]

branchOperand :: Text -> Int -> FilePath -> Int -> M.Map Text Int -> Either AsmError Int
branchOperand operand instrAddr fp ln labels =
  if isSimpleLabel operand
    then case M.lookup operand labels of
      Nothing -> Left $ AsmError fp ln $ "undefined label '" <> operand <> "'"
      Just t -> checkOff (t - instrAddr)
    else checkOff =<< evalExpr operand labels fp ln
  where
    checkOff offset =
      if offset < -64 || offset > 63
        then
          Left $
            AsmError fp ln $
              "branch offset "
                <> (if offset > 0 then "+" else "")
                <> T.pack (show offset)
                <> " out of range (-64..63)"
        else Right offset

encLi :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encLi fp ln ops labels = do
  expectCount fp ln "li" ops 2
  rd <- reg fp ln (ops !! 0)
  when (rd == 0) $ Left $ AsmError fp ln "li cannot target r0"
  val0 <- evalExpr (ops !! 1) labels fp ln
  if val0 < -2048 || val0 > wordMask
    then Left $ AsmError fp ln $ "li value " <> T.pack (show val0) <> " out of 12-bit range"
    else
      let val = val0 .&. wordMask
          lower = val .&. imm6Mask
          upper = (val `shiftR` 6) .&. imm6Mask
       in Right [encodeRI luiOp rd upper, encodeRI addiOp rd lower]

encJmp :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encJmp fp ln ops labels = do
  expectCount fp ln "jmp" ops 1
  val <- (.&. wordMask) <$> evalExpr (head ops) labels fp ln
  let lower = val .&. imm6Mask
      upper = (val `shiftR` 6) .&. imm6Mask
  Right
    [ encodeRI luiOp 4 upper,
      encodeRI addiOp 4 lower,
      encodeR3 specOp 0 4 jalrRb
    ]

encCall :: FilePath -> Int -> [Text] -> M.Map Text Int -> Either AsmError [Int]
encCall fp ln ops labels = do
  expectCount fp ln "call" ops 1
  val <- (.&. wordMask) <$> evalExpr (head ops) labels fp ln
  let lower = val .&. imm6Mask
      upper = (val `shiftR` 6) .&. imm6Mask
  Right
    [ encodeRI luiOp 4 upper,
      encodeRI addiOp 4 lower,
      encodeR3 specOp 5 4 jalrRb
    ]

encOr :: FilePath -> Int -> [Text] -> Either AsmError [Int]
encOr fp ln ops = do
  expectCount fp ln "or" ops 3
  rx <- reg fp ln (ops !! 0)
  ry <- reg fp ln (ops !! 1)
  rz <- reg fp ln (ops !! 2)
  when (rx == 4) $ Left $ AsmError fp ln "or: destination cannot be r4 (assembler scratch)"
  Right
    [ encodeR3 andOp 4 ry rz,
      encodeR3 addOp rx ry rz,
      encodeR3 subOp rx rx 4
    ]

encXor :: FilePath -> Int -> [Text] -> Either AsmError [Int]
encXor fp ln ops = do
  expectCount fp ln "xor" ops 3
  rx <- reg fp ln (ops !! 0)
  ry <- reg fp ln (ops !! 1)
  rz <- reg fp ln (ops !! 2)
  when (rx == 4) $ Left $ AsmError fp ln "xor: destination cannot be r4 (assembler scratch)"
  Right
    [ encodeR3 andOp 4 ry rz,
      encodeR3 addOp rx ry rz,
      encodeR3 subOp rx rx 4,
      encodeR3 subOp rx rx 4
    ]
