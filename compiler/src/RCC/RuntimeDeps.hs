{-# LANGUAGE OverloadedStrings #-}
-- | Which @lib/*.s@ files to @%include@ after user code for a given TAC program.
module RCC.RuntimeDeps
  ( asmCalleeName
  , floatRuntimeIncludeLines
  , floatRuntimeIncludeLinesAll
  ) where

import Data.Foldable (foldl')
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import qualified Data.Set as Set
import Data.Set (Set)
import Data.Text (Text)

import qualified RCC.TAC as TAC

-- | Assembly entry symbol for calls emitted from TAC (libc float I/O uses @__*@ names).
asmCalleeName :: Text -> Text
asmCalleeName f
  | f == "atof" = "__atof"
  | f == "ftoa" = "__ftoa"
  | otherwise   = f

commonFloat :: [Text]
commonFloat = ["float/_float_store_helpers.s", "float/_float_pack_helpers.s"]

-- | Per public float routine: files needed when that symbol is referenced.
routineFileDeps :: Map Text [Text]
routineFileDeps = Map.fromList
  [ ("__fcopy", commonFloat ++ ["float/__fcopy.s"])
  , ("__fneg",  commonFloat ++ ["float/__fneg.s"])
  , ("__fadd",  commonFloat ++ ["float/__fcopy.s", "float/__fadd.s"])
  , ("__fsub",  commonFloat ++ ["float/__fcopy.s", "float/__fadd.s", "float/__fsub.s"])
  , ("__fmul",  commonFloat ++ ["float/__fmul.s"])
  , ("__fdiv",  commonFloat ++ ["float/__fdiv.s"])
  , ("__fcmp",  commonFloat ++ ["float/__fcmp.s"])
  , ("__ftoi",  commonFloat ++ ["float/__ftoi.s"])
  , ("__itof",  commonFloat ++ ["float/__itof.s"])
  , ("__atof",  commonFloat ++
      [ "float/__itof.s", "float/__fadd.s", "float/__fmul.s"
      , "float/__fdiv.s", "float/__fneg.s", "float/__fcopy.s"
      , "float/__atof.s"
      ])
  , ("__ftoa",  commonFloat ++
      [ "float/__fcopy.s", "float/__fneg.s", "float/__ftoi.s"
      , "float/__itof.s", "float/__fadd.s", "float/__fsub.s"
      , "float/__fmul.s", "itoa.s", "float/__ftoa.s"
      ])
  ]

-- | Include order: dependencies before dependents (matches @tools/tests/float/run_float_tests.py@).
masterFloatFileOrder :: [Text]
masterFloatFileOrder =
  [ "float/_float_store_helpers.s"
  , "float/_float_pack_helpers.s"
  , "float/__fcopy.s"
  , "float/__fneg.s"
  , "float/__fadd.s"
  , "float/__fsub.s"
  , "float/__fmul.s"
  , "float/__fdiv.s"
  , "float/__fcmp.s"
  , "float/__ftoi.s"
  , "float/__itof.s"
  , "float/__atof.s"
  , "itoa.s"
  , "float/__ftoa.s"
  ]

collectUsedFloatRoutines :: TAC.TACProg -> Set Text
collectUsedFloatRoutines (TAC.TACProg _ procs) =
  foldl' (\acc p -> foldl' scanInstr acc (TAC.procInstrs p)) Set.empty procs
  where
    scanInstr s (TAC.ICall _ fname _) =
      let n = asmCalleeName fname
      in if Map.member n routineFileDeps then Set.insert n s else s
    scanInstr s _ = s

-- | @itoa@ is resolved from @lib/itoa.s@ (not emitted as C) when this holds.
usesStandaloneLibItoa :: TAC.TACProg -> Bool
usesStandaloneLibItoa (TAC.TACProg _ procs) =
  any (\p -> any isItoa (TAC.procInstrs p)) procs
  where
    isItoa (TAC.ICall _ fname _) = fname == "itoa"
    isItoa _ = False

-- | Every soft-float @%include@ in dependency order (for the primary object in
--   a multi-file link where other objects call helpers this TU does not reference).
floatRuntimeIncludeLinesAll :: [Text]
floatRuntimeIncludeLinesAll =
  let allFiles =
        Set.unions
          [ Set.fromList fs
          | fs <- Map.elems routineFileDeps
          ]
   in [ "%include \"" <> f <> "\""
      | f <- masterFloatFileOrder
      , f `Set.member` allFiles
      ]

-- | @%include@ lines (paths relative to @lib/@, for @ras -I lib@). Empty if no soft-float is used.
floatRuntimeIncludeLines :: TAC.TACProg -> [Text]
floatRuntimeIncludeLines prog =
  let used = collectUsedFloatRoutines prog
      neededFloat = Set.unions
        [ Set.fromList (Map.findWithDefault [] sym routineFileDeps)
        | sym <- Set.elems used
        ]
      -- @lib/itoa.s@ is much smaller than rcc-emitted C @itoa@. Pull it in when @itoa@ is
      -- called but @__ftoa@ did not already add @itoa.s@ via @routineFileDeps@.
      neededItoa =
        if usesStandaloneLibItoa prog && not ("itoa.s" `Set.member` neededFloat)
          then Set.singleton "itoa.s"
          else Set.empty
      needed = neededFloat `Set.union` neededItoa
  in if Set.null needed
       then []
       else
         [ "%include \"" <> f <> "\""
         | f <- masterFloatFileOrder
         , f `Set.member` needed
         ]
