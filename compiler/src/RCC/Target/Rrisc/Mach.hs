{-# LANGUAGE LambdaCase #-}
-- | Typed RRISC machine instructions and assembly lines before textual rendering.
module RCC.Target.Rrisc.Mach
  ( Reg (..)
  , reg
  , MachLabel
  , Imm6 (..)
  , imm6
  , Imm12 (..)
  , MachInsn (..)
  , AsmLine (..)
  , machLoadConst
  , renderAsmProgram
  ) where

import Data.Bits ((.&.), shiftR)
import Data.Text (Text)
import qualified Data.Text as T
import Numeric (showOct)

-- ---------------------------------------------------------------------------
-- Registers

data Reg = R0 | R1 | R2 | R3 | R4 | R5 | R6 | R7
  deriving (Eq, Ord, Show, Enum)

reg :: Int -> Reg
reg n = case n of
  0 -> R0
  1 -> R1
  2 -> R2
  3 -> R3
  4 -> R4
  5 -> R5
  6 -> R6
  7 -> R7
  _ -> error ("RCC.Target.Rrisc.Mach.reg: invalid register index " <> show n)

prettyReg :: Reg -> Text
prettyReg r = "r" <> T.pack (show (fromEnum r))

-- ---------------------------------------------------------------------------
-- Labels (branch / symbol names)

type MachLabel = Text

-- ---------------------------------------------------------------------------
-- Immediates

-- | Unsigned 6-bit immediate for RI instructions (0..63).
newtype Imm6 = Imm6 { imm6Word :: Int }
  deriving (Eq, Show)

imm6 :: Int -> Imm6
imm6 n
  | n >= 0 && n <= 63 = Imm6 n
  | otherwise = error ("RCC.Target.Rrisc.Mach.imm6: out of range " <> show n)

prettyImm6 :: Imm6 -> Text
prettyImm6 = T.pack . show . imm6Word

-- | Right-hand side of @li@ or similar 12-bit immediate printing policy.
data Imm12 = Imm12Dec Int | Imm12Oct Int
  deriving (Eq, Show)

prettyImm12 :: Imm12 -> Text
prettyImm12 (Imm12Dec n) = T.pack (show (n .&. 0xFFF))
prettyImm12 (Imm12Oct n) = "0o" <> T.pack (showOct (n .&. 0xFFF) "")

-- ---------------------------------------------------------------------------
-- Machine instructions (mnemonics the compiler emits)

data MachInsn
  = IAnd Reg Reg Reg
  | ISub Reg Reg Reg
  | IAdd Reg Reg Reg
  | ILwr Reg Reg
  | ISwr Reg Reg
  | ILui Reg Imm6
  | IAddi Reg Imm6
  | ISubi Reg Imm6
  | IBf MachLabel
  | IBt MachLabel
  | IJalr Reg Reg
  | IClrt
  | IRol Reg Reg
  | IRor Reg Reg
  | ILi Reg Imm12
  | ILiLabel Reg MachLabel
  deriving (Eq, Show)

commaSep :: [Text] -> Text
commaSep = T.intercalate ", "

prettyMachInsn :: MachInsn -> Text
prettyMachInsn = \case
  IAnd rd ra rb ->
    "and " <> commaSep [prettyReg rd, prettyReg ra, prettyReg rb]
  ISub rd ra rb ->
    "sub " <> commaSep [prettyReg rd, prettyReg ra, prettyReg rb]
  IAdd rd ra rb ->
    "add " <> commaSep [prettyReg rd, prettyReg ra, prettyReg rb]
  ILwr rd ra ->
    "lwr " <> commaSep [prettyReg rd, prettyReg ra]
  ISwr rd ra ->
    "swr " <> commaSep [prettyReg rd, prettyReg ra]
  ILui rd im ->
    "lui " <> prettyReg rd <> ", " <> prettyImm6 im
  IAddi rd im ->
    "addi " <> prettyReg rd <> ", " <> prettyImm6 im
  ISubi rd im ->
    "subi " <> prettyReg rd <> ", " <> prettyImm6 im
  IBf lbl -> "bf " <> lbl
  IBt lbl -> "bt " <> lbl
  IJalr rd ra ->
    "jalr " <> commaSep [prettyReg rd, prettyReg ra]
  IClrt -> "clrt"
  IRol rd ra ->
    "rol " <> commaSep [prettyReg rd, prettyReg ra]
  IRor rd ra ->
    "ror " <> commaSep [prettyReg rd, prettyReg ra]
  ILi rd im ->
    "li " <> prettyReg rd <> ", " <> prettyImm12 im
  ILiLabel rd sym ->
    "li " <> prettyReg rd <> ", " <> sym

-- ---------------------------------------------------------------------------
-- Full assembly lines (prelude, directives, comments, code)

data AsmLine
  = AsmBlank
  | -- | Assembler listing-style comment (@; ...@), one semicolon.
    AsmSemiComment Text
  | -- | Source annotation from TAC (@;; ...@).
    AsmComment Text
  | AsmPreprocDefine Text Text
  | AsmPreprocInclude Text
  | AsmSection Text
  | AsmGlobal MachLabel
  | AsmLabelDef MachLabel
  | AsmDirWord [Int]
  | AsmDirFill Int
  | AsmInstr MachInsn
  | AsmUserAsmInline Text
  deriving (Eq, Show)

asmIndent :: Text -> Text
asmIndent t = "    " <> t

renderAsmLine :: AsmLine -> Text
renderAsmLine = \case
  AsmBlank -> ""
  AsmSemiComment t -> "; " <> t
  AsmComment t -> ";; " <> t
  AsmPreprocDefine name val -> "%define " <> name <> " " <> val
  AsmPreprocInclude path -> "%include \"" <> path <> "\""
  AsmSection sec -> asmIndent (".section " <> sec)
  AsmGlobal sym -> asmIndent (".global " <> sym)
  AsmLabelDef sym -> sym <> ":"
  AsmDirWord ws ->
    asmIndent (".word " <> T.intercalate ", " (map (T.pack . show) ws))
  AsmDirFill n -> asmIndent (".fill " <> T.pack (show n))
  AsmInstr mi -> asmIndent (prettyMachInsn mi)
  AsmUserAsmInline txt ->
    T.unlines $ map asmIndent $ filter (not . T.null) $ T.lines txt

renderAsmProgram :: [AsmLine] -> Text
renderAsmProgram = T.unlines . map renderAsmLine

-- ---------------------------------------------------------------------------
-- Constant loading (matches former Codegen.emitLoadConst policy)

machLoadConst :: Reg -> Int -> [MachInsn]
machLoadConst r n =
  let val = n .&. 0xFFF
      ri = fromEnum r
   in case () of
        _ | val == 0 -> [IAnd r R0 R0]
          | val == 0xFFF -> [IAnd r R7 R7]
          | val .&. 0x3F == 0, ri /= 0, ri /= 7 ->
              [ILui r (imm6 (val `shiftR` 6))]
          | otherwise -> [ILi r (Imm12Dec val)]
