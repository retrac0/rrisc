-- | C type layout in words, parameterized by a target 'DataLayout'.
module RCC.Frontend.C.Layout
  ( cTySizeWords
  , structFieldOffsetWords
  ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)

import qualified RCC.Frontend.C.Syntax as Syn
import RCC.Ir.DataLayout (DataLayout (..))

-- | Size of a C type in words (mirrors legacy @Sema.tySize@, but uses @DataLayout@).
cTySizeWords :: DataLayout -> Map Text [Syn.Field] -> Syn.Ty -> Int
cTySizeWords dl _  Syn.TyInt          = dlIntWords dl
cTySizeWords dl _  Syn.TyUint         = dlUintWords dl
cTySizeWords dl _  Syn.TyVoid         = dlVoidWords dl
cTySizeWords dl _  Syn.TyFloat        = dlFloatWords dl
cTySizeWords dl _  (Syn.TyPtr _)      = dlPtrWords dl
cTySizeWords dl ss (Syn.TyArray t n)  = cTySizeWords dl ss t * n
cTySizeWords dl ss (Syn.TyStruct _ n) = case Map.lookup n ss of
  Just fs -> sum (map (cTySizeWords dl ss . Syn.fieldTy) fs)
  Nothing -> 0

structFieldOffsetWords :: DataLayout -> Map Text [Syn.Field] -> Text -> Text -> Maybe Int
structFieldOffsetWords dl ss sname fname = do
  fs <- Map.lookup sname ss
  go 0 fs
  where
    go _ [] = Nothing
    go acc (f : fs')
      | Syn.fieldName f == fname = Just acc
      | otherwise = go (acc + cTySizeWords dl ss (Syn.fieldTy f)) fs'
