{-# LANGUAGE OverloadedStrings #-}
-- | Shared numeric parsing for @rcc@ CLI flags (@0o@ / @0x@ / decimal).
module RCC.CliParse (parseIntArg) where

parseIntArg :: String -> Either String Int
parseIntArg s0 =
  let s = trim s0
   in if null s
        then Left "empty integer"
        else go s
  where
    trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')

    go ('0' : 'o' : ds) | not (null ds) = readBase 8 ds
    go ('0' : 'O' : ds) | not (null ds) = readBase 8 ds
    go ('0' : 'x' : ds) | not (null ds) = readBase 16 ds
    go ('0' : 'X' : ds) | not (null ds) = readBase 16 ds
    go ('0' : 'b' : ds) | not (null ds) = readBase 2 ds
    go ('0' : 'B' : ds) | not (null ds) = readBase 2 ds
    go v = case reads v :: [(Int, String)] of
      [(n, "")] -> Right n
      _ -> Left ("not an integer: " <> v)

    readBase :: Int -> String -> Either String Int
    readBase b ds =
      case traverse (val b) ds of
        Just digits -> Right (foldl1 (\a d -> a * b + d) digits)
        Nothing -> Left ("invalid digits for base " <> show b <> " in " <> show ds)

    val :: Int -> Char -> Maybe Int
    val b c
      | c >= '0' && c <= '9' && fromEnum c - fromEnum '0' < b =
          Just (fromEnum c - fromEnum '0')
      | c >= 'a' && c <= 'f' && b == 16 =
          Just (fromEnum c - fromEnum 'a' + 10)
      | c >= 'A' && c <= 'F' && b == 16 =
          Just (fromEnum c - fromEnum 'A' + 10)
      | otherwise = Nothing
