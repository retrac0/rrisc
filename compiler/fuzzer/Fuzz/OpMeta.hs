{-# LANGUAGE LambdaCase #-}
-- | Per-operator metadata, used by both the generator and the printer.
--
-- This module is the single source of truth for everything the fuzzer
-- needs to know about a 'BinOp' / 'UnOp' / 'AssOp':
--
--   * its surface syntax, so the printer can emit it;
--   * its precedence class, so the printer can place parens correctly;
--   * whether its result can exceed 12 bits on a 32-bit host gcc, so the
--     host-target printer knows when to wrap the result in @& 0xFFF@;
--   * whether its operand needs an @(unsigned)@ cast on *both* targets,
--     so signed-vs-unsigned C semantics line up between rcc's 12-bit
--     @int@ and gcc's 32-bit @int@;
--   * whether its result is a 0/1 boolean (no mask, no cast needed);
--   * a generator weight, so 'Fuzz.Gen' can pick operators by frequency
--     without redeclaring them.
--
-- Invariant: every 'BinOp' / 'UnOp' / 'AssOp' constructor must appear
-- exactly once in 'binMeta' / 'unMeta' / 'assMeta'.  The unit-test in
-- "Fuzz.OpMeta" enforces totality (TODO).
module Fuzz.OpMeta
  ( -- * Precedence
    P (..)
  , succP
    -- * Per-op metadata
  , BinMeta (..)
  , UnMeta (..)
  , AssMeta (..)
  , binMeta
  , unMeta
  , assMeta
    -- * Convenience accessors
  , allBinOps
  , allUnOps
  , allAssOps
  , assToBinOp
  ) where

import Data.Text (Text)

import Fuzz.AST

-- ---------------------------------------------------------------------------
-- Precedence

-- | Coarse-grained precedence classes.  Smaller (lower in the data type)
-- means looser binding, e.g. 'PAss' is among the loosest and 'PAtom' tightest.
data P
  = PAss      -- = += -= *= … (loosest among generated ops)
  | PCond     -- ?:  (right-assoc, between assignment and || in C)
  | PLOr      -- ||
  | PLAnd     -- &&
  | POr       -- |
  | PXor      -- ^
  | PAnd      -- &
  | PEq       -- == !=
  | PRel      -- < <= > >=
  | PShift    -- << >>
  | PAdd      -- + -
  | PMul      -- * / %
  | PUn       -- unary - ~ ! ++ --
  | PAtom     -- variable, literal, parenthesised expression (tightest)
  deriving (Eq, Ord, Show)

-- | Tighten one level for the right operand of a left-associative binary
-- operator.  Used in the printer so @a - b - c@ renders as @a - b - c@,
-- not @a - (b - c)@.
succP :: P -> P
succP = \case
  PAss   -> PCond
  PCond  -> PLOr
  PLOr   -> PLAnd
  PLAnd  -> POr
  POr    -> PXor
  PXor   -> PAnd
  PAnd   -> PEq
  PEq    -> PRel
  PRel   -> PShift
  PShift -> PAdd
  PAdd   -> PMul
  PMul   -> PUn
  PUn    -> PAtom
  PAtom  -> PAtom

-- ---------------------------------------------------------------------------
-- Binary operators

data BinMeta = BinMeta
  { bmSym             :: !Text   -- C surface syntax, e.g. "+"
  , bmPrec            :: !P      -- precedence class
  , bmOverflowsOnHost :: !Bool   -- true ⇒ wrap result in @& 0xFFF@ on host
  , bmNeedsUnsignedLhs :: !Bool  -- true ⇒ cast LHS to @unsigned@ on both targets
  , bmResultIsBool    :: !Bool   -- true ⇒ result is 0 or 1
  , bmGenWeight       :: !Int    -- frequency in 'Fuzz.Gen.pickBinOp'
  }

binMeta :: BinOp -> BinMeta
binMeta = \case
  -- Arithmetic that can exceed 12 bits on a 32-bit host gcc.  We force
  -- unsigned modular semantics on both targets via the LHS cast, then
  -- truncate to 12 bits on the host.
  OAdd -> BinMeta "+"  PAdd   True  True  False 4
  OSub -> BinMeta "-"  PAdd   True  True  False 4
  OMul -> BinMeta "*"  PMul   True  True  False 3

  -- Bitwise ops on values already in [0, 4095] stay in [0, 4095].  No host
  -- mask is needed and no LHS cast is required: when both operands are
  -- typed @unsigned@ and large literals follow C's "first type that fits"
  -- rule, the usual conversions kick in naturally and the result is well
  -- defined on both sides.
  OBand -> BinMeta "&" PAnd   False False False 3
  OBor  -> BinMeta "|" POr    False False False 3
  OBxor -> BinMeta "^" PXor   False False False 3

  -- Shift: @<<@ on a signed @int@ whose result doesn't fit is UB, and
  -- platform widths differ (12 vs 32 bits).  Cast LHS to @unsigned@ on
  -- both, then mask the host result.  @>>@ on unsigned can never grow the
  -- value, so no host mask, but the cast is still needed to pin down
  -- "logical right shift" on both targets.
  OShl  -> BinMeta "<<" PShift True  True  False 1
  OShr  -> BinMeta ">>" PShift False True  False 1

  -- Comparisons always return 0 or 1.  Both targets must agree on the
  -- ordering, which means signed-vs-unsigned matters.  We rely on rcc's
  -- (recently fixed) "usual arithmetic conversions" to choose the right
  -- TAC compare op based on operand types; the LHS cast helper isn't
  -- needed here because we don't generate signed locals yet.
  OEq -> BinMeta "==" PEq    False False True  2
  ONe -> BinMeta "!=" PEq    False False True  2
  OLt -> BinMeta "<"  PRel   False False True  2
  OLe -> BinMeta "<=" PRel   False False True  2
  OGt -> BinMeta ">"  PRel   False False True  2
  OGe -> BinMeta ">=" PRel   False False True  2

  -- Short-circuit logical ops always yield 0 or 1.  No mask, no LHS
  -- cast.  But the printer treats them specially: the *children* are
  -- not wrapped in @& 0xFFF@ either, because the value is collapsed to
  -- 0/1 by the implicit @!= 0@ at the top of each operand.  We emit
  -- them with surrounding parens to make the short-circuit boundary
  -- visible — important for catching evaluation-order bugs.
  OAnd -> BinMeta "&&" PLAnd  False False True  1
  OOr  -> BinMeta "||" PLOr   False False True  1

-- ---------------------------------------------------------------------------
-- Unary operators

data UnMeta = UnMeta
  { umSym             :: !Text
  , umPrec            :: !P
  , umOverflowsOnHost :: !Bool
  , umNeedsUnsignedCast :: !Bool  -- cast operand to @unsigned@ on both targets
  , umResultIsBool    :: !Bool
  , umGenWeight       :: !Int
  }

unMeta :: UnOp -> UnMeta
unMeta = \case
  -- @-(unsigned)x@ on rcc is a 12-bit value; on host it's a huge 32-bit
  -- number.  The cast forces unsigned modular semantics; the host mask
  -- truncates back to 12 bits.
  UNeg  -> UnMeta "-" PUn True  True  False 1
  -- @~(unsigned)x@ on rcc flips bottom 12 bits; on host flips all 32.
  -- Same fix.
  UBNot -> UnMeta "~" PUn True  True  False 1
  -- @!x@ always yields 0 or 1; no mask, no cast.
  UNot  -> UnMeta "!" PUn False False True  1
  -- Pre / post increment / decrement.  These mutate the operand (an
  -- lvalue), so the operand must NOT be cast — the cast would produce
  -- an rvalue and the C compiler would reject the program.  The result
  -- can overflow on host (e.g. @v++@ when @v == 0xFFF@), so the host
  -- emitter wraps the *whole* @++v@ / @v++@ expression in @& 0xFFF@,
  -- and the underlying mutated lvalue is restored to 12 bits via the
  -- 'umLvalueMaskOnHost' field below — see 'Fuzz.Print'.
  UPreInc  -> UnMeta "++" PUn True  False False 1
  UPostInc -> UnMeta "++" PUn True  False False 1
  UPreDec  -> UnMeta "--" PUn True  False False 1
  UPostDec -> UnMeta "--" PUn True  False False 1

-- ---------------------------------------------------------------------------
-- Compound assignments

data AssMeta = AssMeta
  { amSym             :: !Text
  , amOverflowsOnHost :: !Bool   -- true ⇒ host needs the result-mask trick
  , amBaseBinOp       :: !(Maybe BinOp)
                                  -- ^ For non-AEq, the underlying binary op.
                                  --   Lets the printer desugar
                                  --   @x += y@ → @x = (x + y) & 0xFFF@ on host.
  }

assMeta :: AssOp -> AssMeta
assMeta = \case
  AEq   -> AssMeta "="    False Nothing
  AAdd  -> AssMeta "+="   True  (Just OAdd)
  ASub  -> AssMeta "-="   True  (Just OSub)
  AMul  -> AssMeta "*="   True  (Just OMul)
  ABand -> AssMeta "&="   False (Just OBand)
  ABor  -> AssMeta "|="   False (Just OBor)
  ABxor -> AssMeta "^="   False (Just OBxor)
  AShl  -> AssMeta "<<="  True  (Just OShl)
  AShr  -> AssMeta ">>="  False (Just OShr)

-- ---------------------------------------------------------------------------
-- Enumeration

-- | Every 'BinOp' the fuzzer knows about.  Generator paths that pick a
-- random op should pull from this list (filtered/weighted by 'bmGenWeight').
allBinOps :: [BinOp]
allBinOps =
  [ OAdd, OSub, OMul
  , OBand, OBor, OBxor
  , OShl, OShr
  , OEq, ONe, OLt, OLe, OGt, OGe
  ]

allUnOps :: [UnOp]
allUnOps = [UNeg, UBNot, UNot]

allAssOps :: [AssOp]
allAssOps = [AEq, AAdd, ASub, AMul, ABand, ABor, ABxor, AShl, AShr]

-- | The binary operator behind a compound assignment, if any.
assToBinOp :: AssOp -> Maybe BinOp
assToBinOp = amBaseBinOp . assMeta
