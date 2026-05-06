module RCC.Parser
  ( parseProgram
  ) where

import Control.Monad (void)
import qualified Data.List.NonEmpty as NE
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void, absurd)
import Text.Megaparsec hiding (Pos)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

import RCC.Error (Pos(..), Span(..), Diagnostic(..), Severity(..))
import RCC.Syntax

-- ---------------------------------------------------------------------------
-- Parser type

type Parser = Parsec Void Text

-- ---------------------------------------------------------------------------
-- Entry point

parseProgram :: FilePath -> Text -> Either Diagnostic Prog
parseProgram fp src =
  case parse (sc *> program <* eof) fp src of
    Left  bundle -> Left  (convertError fp bundle)
    Right prog   -> Right prog

-- ---------------------------------------------------------------------------
-- Error conversion

convertError :: FilePath -> ParseErrorBundle Text Void -> Diagnostic
convertError fp bundle = Diagnostic
  { diagSpan     = Span pos pos
  , diagSeverity = SevError
  , diagMessage  = mkMessage firstErr
  }
  where
    firstErr    = NE.head (bundleErrors bundle)
    (_, pstate) = reachOffset (errorOffset firstErr) (bundlePosState bundle)
    srcPos      = pstateSourcePos pstate
    pos         = Pos fp (unPos (sourceLine srcPos)) (unPos (sourceColumn srcPos))

    mkMessage (TrivialError _ mUnexp expSet) =
      T.unwords $ filter (not . T.null)
        [ maybe "" (\u -> "unexpected " <> showEI u) mUnexp
        , if Set.null expSet then ""
          else "expected " <> T.intercalate ", " (map showEI (Set.toList expSet))
        ]
    mkMessage (FancyError _ errs) =
      T.intercalate ", " (map showFE (Set.toList errs))

    showFE (ErrorFail msg)          = T.pack msg
    showFE (ErrorIndentation _ _ _) = "indentation error"
    showFE (ErrorCustom v)          = absurd v
    showEI (Tokens ts)  = "'" <> T.pack (NE.toList ts) <> "'"
    showEI (Label  lbl) = T.pack (NE.toList lbl)
    showEI EndOfInput   = "end of input"

-- ---------------------------------------------------------------------------
-- Whitespace and lexemes

sc :: Parser ()
sc = L.space space1
       (L.skipLineComment  "//")
       (L.skipBlockComment "/*" "*/")

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

semi :: Parser ()
semi = void (symbol ";")

-- ---------------------------------------------------------------------------
-- Identifiers and keywords

keywords :: Set Text
keywords = Set.fromList
  [ "int", "void", "struct", "typedef", "const"
  , "unsigned", "bool", "true", "false"
  , "if", "else", "while", "for", "return"
  , "break", "continue", "sizeof", "asm"
  ]

ident :: Parser Text
ident = lexeme $ do
  c  <- letterChar <|> char '_'
  cs <- many (alphaNumChar <|> char '_')
  let name = T.pack (c : cs)
  if name `Set.member` keywords
    then fail $ "keyword '" <> T.unpack name <> "' used as identifier"
    else return name

keyword :: Text -> Parser ()
keyword kw = lexeme $ string kw *> notFollowedBy (alphaNumChar <|> char '_')

-- ---------------------------------------------------------------------------
-- Integer literals

intLit :: Parser Int
intLit = lexeme $ choice
  [ string "0o" *> L.octal
  , string "0x" *> L.hexadecimal
  , string "0b" *> L.binary
  , L.decimal
  ]

-- ---------------------------------------------------------------------------
-- Source position helpers

getPos :: Parser Pos
getPos = do
  sp <- getSourcePos
  pure $ Pos (sourceName sp) (unPos (sourceLine sp)) (unPos (sourceColumn sp))

withSpan :: Parser a -> Parser (Span, a)
withSpan p = do
  start <- getPos
  x     <- p
  end   <- getPos
  pure (Span start end, x)

mkSpan :: Expr -> Expr -> Span
mkSpan l r = Span (spanStart (exprSpan l)) (spanEnd (exprSpan r))

-- ---------------------------------------------------------------------------
-- Types

parseTy :: Parser Ty
parseTy = do
  base <- baseTy
  ptrs <- many (symbol "*")
  pure $ foldl (\t _ -> TyPtr t) base ptrs

baseTy :: Parser Ty
baseTy = choice
  [ TyInt  <$  keyword "int"
  , TyVoid <$  keyword "void"
  , TyInt  <$  keyword "bool"
  , TyUint <$  (keyword "unsigned" <* optional (keyword "int"))
  , do keyword "struct"
       (sp, name) <- withSpan ident   -- sp = span of the struct-name token
       pure $ TyStruct sp name
  ]

-- ---------------------------------------------------------------------------
-- Top-level program

program :: Parser Prog
program = Prog <$> many topDecl

topDecl :: Parser TopDecl
topDecl = choice
  [ try (TDStruct <$> structDecl)
  , try typedef_
  , try (TDFunc <$> funcDecl)
  , TDVar     <$> varDecl
  ]

typedef_ :: Parser TopDecl
typedef_ = do
  (sp, _) <- withSpan (keyword "typedef")
  ty      <- parseTy
  name    <- ident
  semi
  pure $ TDTypedef sp ty name

-- ---------------------------------------------------------------------------
-- Struct declarations

structDecl :: Parser StructDecl
structDecl = do
  (sp, _) <- withSpan (keyword "struct")
  name    <- ident
  void (symbol "{")
  fields  <- many field
  void (symbol "}")
  semi
  pure $ StructDecl sp name fields

field :: Parser Field
field = do
  ty   <- parseTy
  name <- ident
  ty'  <- arrSuffix ty
  semi
  pure $ Field ty' name

arrSuffix :: Ty -> Parser Ty
arrSuffix ty = option ty $
  TyArray ty <$> between (symbol "[") (symbol "]") intLit

-- ---------------------------------------------------------------------------
-- Function declarations

funcDecl :: Parser FuncDecl
funcDecl = do
  (sp, retTy) <- withSpan parseTy
  name        <- ident
  params      <- between (symbol "(") (symbol ")") (sepBy param (symbol ","))
  body        <- choice [ Just <$> block, Nothing <$ semi ]
  pure $ FuncDecl sp retTy name params body

param :: Parser (Ty, Text)
param = do
  ty   <- parseTy
  name <- ident
  pure (ty, name)

-- ---------------------------------------------------------------------------
-- Variable declarations

varDecl :: Parser VarDecl
varDecl = do
  start    <- getPos
  isConst  <- option False (True <$ keyword "const")
  ty       <- parseTy
  (nameSp, name) <- withSpan ident   -- capture name span for error reporting
  ty'      <- arrSuffix ty
  ini      <- optional (symbol "=" *> initialiser)
  end      <- getPos
  semi
  pure $ VarDecl (Span start end) (spanStart nameSp) isConst ty' name ini

initialiser :: Parser Init
initialiser = choice
  [ IList <$> between (symbol "{") (symbol "}") (sepBy expr (symbol ","))
  , IExpr <$> expr
  ]

-- ---------------------------------------------------------------------------
-- Statements

block :: Parser Block
block = between (symbol "{") (symbol "}") (many stmt)

stmt :: Parser Stmt
stmt = choice
  [ try (SVarDecl <$> varDecl)
  , sif, swhile, sfor
  , sreturn, sbreak, scontinue, sasmInline
  , do sp   <- fst <$> withSpan (symbol "{")
       ss   <- many stmt
       void (symbol "}")
       pure (SBlock sp ss)
  , do (sp, e) <- withSpan expr
       semi
       pure (SExpr sp e)
  ]

sif :: Parser Stmt
sif = do
  (sp, _) <- withSpan (keyword "if")
  cond    <- between (symbol "(") (symbol ")") expr
  thn     <- braceOrStmt
  els     <- optional (keyword "else" *> braceOrStmt)
  pure $ SIf sp cond thn els

swhile :: Parser Stmt
swhile = do
  (sp, _) <- withSpan (keyword "while")
  cond    <- between (symbol "(") (symbol ")") expr
  body    <- braceOrStmt
  pure $ SWhile sp cond body

sfor :: Parser Stmt
sfor = do
  (sp, _) <- withSpan (keyword "for")
  void (symbol "(")
  ini  <- forInit
  cond <- optional expr
  semi
  step <- optional expr
  void (symbol ")")
  body <- braceOrStmt
  pure $ SFor sp ini cond step body

forInit :: Parser ForInit
forInit = choice
  [ try (FIDecl <$> varDecl)
  , FIExpr <$> (optional expr <* semi)
  ]

sreturn :: Parser Stmt
sreturn = do
  (sp, _) <- withSpan (keyword "return")
  val     <- optional expr
  semi
  pure $ SReturn sp val

sbreak :: Parser Stmt
sbreak = (\(sp,_) -> SBreak sp) <$> withSpan (keyword "break") <* semi

scontinue :: Parser Stmt
scontinue = (\(sp,_) -> SContinue sp) <$> withSpan (keyword "continue") <* semi

sasmInline :: Parser Stmt
sasmInline = do
  (sp, _) <- withSpan (keyword "asm")
  txt     <- between (symbol "(") (symbol ")") stringLit
  semi
  pure $ SAsmInline sp txt

stringLit :: Parser Text
stringLit = lexeme $ char '"' *> (T.pack <$> many (satisfy (/= '"'))) <* char '"'

braceOrStmt :: Parser Stmt
braceOrStmt = choice
  [ do sp <- fst <$> withSpan (symbol "{")
       ss <- many stmt
       void (symbol "}")
       pure (SBlock sp ss)
  , stmt
  ]

-- ---------------------------------------------------------------------------
-- Expressions

expr :: Parser Expr
expr = assignExpr

-- Left-associative binary level: EBinary span starts at the operator token.
-- Uses 'try' so that a prefix match (e.g. '+' before '+=') can backtrack.
leftAssoc :: Parser Expr -> [(Text, BinOp)] -> Parser Expr
leftAssoc sub ops = do
    x <- sub
    rest x
  where
    opParser = choice [ o <$ symbol sym | (sym, o) <- ops ]
    rest x   = option x $ try $ do
      (opSp, o) <- withSpan opParser        -- operator span
      y         <- sub
      let sp = Span (spanStart opSp) (spanEnd (exprSpan y))
      rest (EBinary sp o x y)

assignExpr :: Parser Expr
assignExpr = do
  lhs <- condExpr
  option lhs $ do
    (sp, op) <- withSpan assignOp
    rhs      <- assignExpr   -- right-associative
    pure $ EAssign sp op lhs rhs

assignOp :: Parser AssOp
assignOp = choice
  [ AEq   <$ symbol  "="
  , AAdd  <$ symbol "+="
  , ASub  <$ symbol "-="
  , AMul  <$ symbol "*="
  , ADiv  <$ symbol "/="
  , AMod  <$ symbol "%="
  , ABand <$ symbol "&="
  , ABor  <$ symbol "|="
  , ABxor <$ symbol "^="
  , AShl  <$ symbol "<<="
  , AShr  <$ symbol ">>="
  ]

condExpr :: Parser Expr
condExpr = lorExpr

lorExpr, landExpr, borExpr, bxorExpr, bandExpr :: Parser Expr
lorExpr  = leftAssoc landExpr  [("||", BOr)]
landExpr = leftAssoc borExpr   [("&&", BAnd)]
borExpr  = leftAssoc bxorExpr  [("|",  BBor)]
bxorExpr = leftAssoc bandExpr  [("^",  BBxor)]
bandExpr = leftAssoc eqExpr    [("&",  BBand)]

eqExpr, relExpr, shiftExpr, addExpr, mulExpr :: Parser Expr
eqExpr   = leftAssoc relExpr   [("==", BEq),  ("!=", BNe)]
relExpr  = leftAssoc shiftExpr [("<=", BLe),  (">=", BGe), ("<", BLt), (">", BGt)]
shiftExpr= leftAssoc addExpr   [("<<", BShl), (">>", BShr)]
addExpr  = leftAssoc mulExpr   [("+",  BAdd),  ("-",  BSub)]
mulExpr  = leftAssoc unaryExpr [("*",  BMul),  ("/",  BDiv), ("%", BMod)]

unaryExpr :: Parser Expr
unaryExpr = choice
  [ unaryOp "!"  UNot
  , unaryOp "-"  UNeg
  , unaryOp "~"  UBNot
  , unaryOp "*"  UDeref
  , unaryOp "&"  UAddrOf
  , unaryOp "++" UPreInc
  , unaryOp "--" UPreDec
  , sizeofExpr
  , try castExpr
  , postfixExpr
  ]
  where
    unaryOp sym op = do
      start <- getPos
      void (symbol sym)
      e <- unaryExpr
      pure $ EUnary (Span start (spanEnd (exprSpan e))) op e

sizeofExpr :: Parser Expr
sizeofExpr = do
  (sp, _) <- withSpan (keyword "sizeof")
  choice
    [ try $ ESizeof sp . Left  <$> between (symbol "(") (symbol ")") parseTy
    ,       ESizeof sp . Right <$> between (symbol "(") (symbol ")") expr
    ]

castExpr :: Parser Expr
castExpr = do
  start <- getPos
  ty    <- between (symbol "(") (symbol ")") parseTy
  e     <- unaryExpr
  pure $ ECast (Span start (spanEnd (exprSpan e))) ty e

postfixExpr :: Parser Expr
postfixExpr = do
  e <- primaryExpr
  rest e
  where
    rest e = option e $ do
      choice
        [ do idx <- between (symbol "[") (symbol "]") expr
             rest (EIndex (mkSpan e idx) e idx)
        , do void (symbol ".")
             f <- ident
             end <- getPos
             rest (EField (Span (spanStart (exprSpan e)) end) e f)
        , do void (symbol "->")
             f <- ident
             end <- getPos
             rest (EArrow (Span (spanStart (exprSpan e)) end) e f)
        , do void (symbol "++")
             end <- getPos
             rest (EPostfix (Span (spanStart (exprSpan e)) end) PostInc e)
        , do void (symbol "--")
             end <- getPos
             rest (EPostfix (Span (spanStart (exprSpan e)) end) PostDec e)
        ]

primaryExpr :: Parser Expr
primaryExpr = choice
  [ do (sp, n) <- withSpan intLit
       pure $ ELit sp n
  , do sp <- fst <$> withSpan (keyword "true")
       pure $ ELit sp 1
  , do sp <- fst <$> withSpan (keyword "false")
       pure $ ELit sp 0
  , do start      <- getPos
       name       <- ident
       end        <- getPos
       let sp = Span start end
       choice
         [ do args <- between (symbol "(") (symbol ")") (sepBy expr (symbol ","))
              end2 <- getPos
              pure $ ECall (Span start end2) name args
         , pure $ EVar sp name
         ]
  , between (symbol "(") (symbol ")") expr
  ]
