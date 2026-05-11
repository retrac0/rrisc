#!/usr/bin/env python3
"""RRISC flat assembler (module ``pytools.asm``).

Usage: python3 -m pytools.asm input.asm [-o output.bin]

Source format:
  %define NAME value     simple text substitution
  %include "file.s"      splice another source file inline
  %macro NAME [p1, p2]   define a parameterized macro (named params)
  %macro NAME N          define a macro with N positional params (%1..%N)
  ...body...
  %endm
  label:                 label (standalone or inline before instruction)
  instruction ops        see Arch.md for full ISA
  ; comment              rest of line ignored
  .word value[, ...]     emit one raw 12-bit word per value
  .float value[, ...]   emit four 12-bit words (48-bit RRISC float) per value
  .fill count[, value]   emit count words of value (default 0)
  .align n               advance address to next multiple of n
  .str "string"          emit UTF-8 bytes of string, one byte per word
  .strz "string"         same as .str plus a trailing 0 word (NUL)
  .org address           set current address counter

Number literals:
  42        decimal
  077       C-style octal (leading zero)
  0xff      hex
  0o77      Python-style octal
  0b1010    binary
"""

import argparse
import os
import re
import sys
from collections import namedtuple
from dataclasses import dataclass, field

from .isa import (OP_ADDI, OP_LUI, OP_AND, OP_ADD, OP_ADDC, OP_SUB, OP_SUBI, OP_SPEC,
                  RB_JALR, RB_ROR, RB_ROL, RB_LWR, RB_SWR,
                  encode_r3, encode_ri, WORD_MASK, IMM6_MASK)
from .float48 import from_float
from .sixbit import encode_sixbit

# -- intermediate data types --

RawLine = namedtuple('RawLine', ['filename', 'lineno', 'text'])
# Flat source line as read from disk (raw text, may have comments).
# Used through include expansion and macro collection/expansion.
# Stored in _flat_lines for listing.

MacroDef = namedtuple('MacroDef', ['params', 'body', 'def_filename', 'def_lineno'])
# body: list[RawLine]

@dataclass(frozen=True)
class SourceLine:
    """A source line after comment stripping, flowing through the symbolic pipeline."""
    filename:     str
    lineno:       int
    text:         str   # comment-stripped, whitespace-stripped; never blank
    source_index: int   # index into _flat_lines for listing

@dataclass
class Statement:
    filename:     str
    lineno:       int
    labels:       list
    mnemonic:     str   # opcode/directive name as parsed; '' for labels-only lines
    operands_str: str   # text after mnemonic, stripped; '' if none
    addr:         int = 0
    source_index: int = 0
    section:      str = "text"  # current section (see ``assign_addresses`` / Layout.hs)

# -- error --

class AsmError(Exception):
    def __init__(self, filename, lineno, msg):
        super().__init__(f"{filename}:{lineno}: {msg}")

# -- helpers --

def _strip_comment(line: str) -> str:
    """Strip a semicolon comment from a line, ignoring semicolons inside quoted strings."""
    in_str = False
    for i, c in enumerate(line):
        if c == '"':
            in_str = not in_str
        elif c == ';' and not in_str:
            return line[:i].rstrip()
    return line

def _reg(s, filename, lineno):
    s = s.strip()
    if re.fullmatch(r'r[0-7]', s):
        return int(s[1])
    raise AsmError(filename, lineno, f"invalid register '{s}'")

def _eval_expr(s, labels, filename, lineno):
    """Evaluate an integer expression; supports + - * / % & | ^ ~ << >> and ().
    Label names resolve via labels dict.  Result is masked to WORD_MASK (12 bits).
    Number literals: decimal, C-style leading-zero octal (077), 0x hex, 0o octal, 0b binary."""
    src = s.strip()
    pos = [0]

    def err(msg):
        raise AsmError(filename, lineno, f"in '{src}': {msg}")

    def ws():
        while pos[0] < len(src) and src[pos[0]].isspace():
            pos[0] += 1

    def peek(n=1):
        ws()
        return src[pos[0]:pos[0] + n] if pos[0] + n <= len(src) else ''

    def eat(n=1):
        ws(); pos[0] += n

    def or_expr():
        v = xor_expr()
        while peek() == '|':
            eat(); v |= xor_expr()
        return v

    def xor_expr():
        v = and_expr()
        while peek() == '^':
            eat(); v ^= and_expr()
        return v

    def and_expr():
        v = shift_expr()
        while peek() == '&':
            eat(); v &= shift_expr()
        return v

    def shift_expr():
        v = add_expr()
        while peek(2) in ('<<', '>>'):
            op = peek(2); eat(2); r = add_expr()
            v = (v << r) if op == '<<' else (v >> r)
        return v

    def add_expr():
        v = mul_expr()
        while peek() in ('+', '-'):
            op = peek(); eat(); r = mul_expr()
            v = v + r if op == '+' else v - r
        return v

    def mul_expr():
        v = unary()
        while True:
            op = peek(2) if peek(2) == '//' else peek()
            if op not in ('*', '/', '//', '%'):
                break
            eat(len(op)); r = unary()
            if r == 0 and op in ('/', '//', '%'):
                err("division by zero")
            v = v * r if op == '*' else v // r if op in ('/', '//') else v % r
        return v

    def unary():
        p = peek()
        if p == '-': eat(); return -unary()
        if p == '+': eat(); return  unary()
        if p == '~': eat(); return ~unary()
        return atom()

    def atom():
        p = peek()
        if p == '(':
            eat(); v = or_expr()
            if peek() != ')': err("expected ')'")
            eat(); return v
        if p.isdigit():
            ws(); i = pos[0]
            while pos[0] < len(src) and (src[pos[0]].isalnum() or src[pos[0]] == '_'):
                pos[0] += 1
            tok = src[i:pos[0]]
            try:
                if len(tok) >= 3 and tok[1:2].lower() in ('x', 'o', 'b'):
                    return int(tok, 0)          # 0x, 0o, 0b explicit prefixes
                if tok[0] == '0' and len(tok) > 1:
                    return int(tok, 8)          # C-style leading-zero octal
                return int(tok, 10)             # decimal
            except ValueError:
                err(f"invalid number '{tok}'")
        if p.isalpha() or p == '_':
            ws(); i = pos[0]
            while pos[0] < len(src) and (src[pos[0]].isalnum() or src[pos[0]] == '_'):
                pos[0] += 1
            name = src[i:pos[0]]
            if name not in labels:
                err(f"undefined label '{name}'")
            return labels[name]
        err("unexpected end of expression" if p == '' else f"unexpected '{p}'")

    if not src:
        raise AsmError(filename, lineno, "empty expression")
    result = or_expr()
    ws()
    if pos[0] != len(src):
        err(f"unexpected '{src[pos[0]:]}'")
    return result


def _imm6(val, filename, lineno):
    """Encode val as unsigned 6-bit field (0..63) — used by lui."""
    if val < 0 or val > 63:
        raise AsmError(filename, lineno, f"immediate {val} out of 6-bit unsigned range (0..63)")
    return val & IMM6_MASK

def _resolve_mem_operand(val, rd, bases, filename, lineno):
    """Resolve a lw/sw address operand to a 6-bit offset."""
    if -32 <= val <= 63:
        return val & IMM6_MASK
    if 0 <= val <= WORD_MASK:
        if rd not in bases:
            raise AsmError(filename, lineno,
                f"address {oct(val)} out of 6-bit range; declare '.base r{rd}, <value>'")
        base = bases[rd]
        if (val & 0o7700) != (base & 0o7700):
            raise AsmError(filename, lineno,
                f"address {oct(val)} not in page of r{rd} "
                f"(base {oct(base)}, page {oct(base & 0o7700)})")
        return val & IMM6_MASK
    raise AsmError(filename, lineno, f"immediate {val} out of 6-bit range (-32..63)")

def _tokenize_line(filename: str, lineno: int, text: str, source_index: int = 0):
    """Parse a comment-stripped, stripped source line into a Statement.
    Returns None for blank lines.  Peels all leading labels."""
    line = text.strip()
    if not line:
        return None
    labels = []
    while True:
        m = re.match(r'([A-Za-z_]\w*)\s*:(.*)', line)
        if not m:
            break
        labels.append(m.group(1))
        line = m.group(2).strip()
    if not line:
        return Statement(filename, lineno, labels, '', '')
    parts = line.split(None, 1)
    return Statement(filename, lineno, labels,
                     parts[0],
                     parts[1].strip() if len(parts) > 1 else '',
                     source_index=source_index)

def _parse_string_literal(s: str, filename: str, lineno: int) -> list:
    """Parse a quoted string literal with \\n and \\\\ escapes."""
    s = s.strip()
    if len(s) < 2 or s[0] != '"' or s[-1] != '"':
        raise AsmError(filename, lineno, "expected a quoted string literal")
    inner = s[1:-1]
    result = []
    i = 0
    while i < len(inner):
        if inner[i] == '\\' and i + 1 < len(inner):
            c = inner[i + 1]
            if c == 'n':
                result.append('\n')
            elif c == '\\':
                result.append('\\')
            else:
                raise AsmError(filename, lineno, f"unknown escape '\\{c}'")
            i += 2
        else:
            result.append(inner[i])
            i += 1
    return result

# -- pipeline stages --

def expand_includes(source: str, src_path, seen=None, include_dirs=()) -> list:
    """Stage 1: recursively splice %include directives.
    Returns list[RawLine] including the %include lines themselves (kept for listing).
    src_path is the path of the file containing source (None for stdin/string input).
    seen is a frozenset of already-included absolute paths for cycle detection.
    include_dirs is a sequence of directories to search for non-absolute includes."""
    src_path = os.path.normpath(os.path.abspath(src_path)) if src_path else None
    src_dir  = os.path.dirname(src_path) if src_path else ''
    if seen is None:
        seen = frozenset({src_path}) if src_path else frozenset()
    out = []
    for lineno, raw in enumerate(source.splitlines(), 1):
        line = _strip_comment(raw).strip()
        m = re.match(r'%include\s+"([^"]+)"\s*$', line)
        if m:
            out.append(RawLine(src_path, lineno, raw))
            inc_rel  = m.group(1)
            if os.path.isabs(inc_rel):
                inc_path = os.path.normpath(inc_rel)
            else:
                candidate = os.path.normpath(os.path.join(src_dir, inc_rel))
                if os.path.exists(candidate):
                    inc_path = candidate
                else:
                    for d in include_dirs:
                        alt = os.path.normpath(os.path.join(d, inc_rel))
                        if os.path.exists(alt):
                            inc_path = alt
                            break
                    else:
                        inc_path = candidate
            if inc_path in seen:
                raise AsmError(src_path, lineno, f"circular %include of '{inc_rel}'")
            try:
                with open(inc_path, encoding='utf-8') as fh:
                    inc_source = fh.read()
            except OSError as e:
                raise AsmError(src_path, lineno,
                               f"cannot open included file '{inc_rel}': {e}")
            out.extend(expand_includes(inc_source, inc_path, seen | {inc_path},
                                       include_dirs))
        else:
            out.append(RawLine(src_path, lineno, raw))
    return out


def collect_macro_defs(lines: list) -> tuple:
    """Stage 2: scan for %macro/%endm blocks.
    Returns (all_lines, macro_table).
    all_lines preserves every input RawLine (definition lines kept for listing).
    macro_table maps name -> MacroDef; body is list[RawLine]."""
    out = []
    macro_table = {}
    i = 0
    while i < len(lines):
        rl = lines[i]
        line = _strip_comment(rl.text).strip()

        if line.startswith('%macro'):
            m = re.match(r'%macro\s+(\w+)\s*(.*)', line)
            if not m:
                raise AsmError(rl.filename, rl.lineno, "malformed %macro directive")
            macro_name = m.group(1)
            params_str = m.group(2).strip()
            if re.fullmatch(r'\d+', params_str):
                # NASM-style: %macro NAME N  (positional params %1..%N)
                params = [f'%{i}' for i in range(1, int(params_str) + 1)]
            elif params_str:
                params = [p.strip() for p in params_str.split(',')]
                for p in params:
                    if not re.fullmatch(r'[A-Za-z_]\w*', p):
                        raise AsmError(rl.filename, rl.lineno,
                                       f"invalid parameter name '{p}' in %macro {macro_name}")
            else:
                params = []
            if macro_name in macro_table:
                raise AsmError(rl.filename, rl.lineno,
                               f"redefinition of macro '{macro_name}'")
            def_filename, def_lineno = rl.filename, rl.lineno
            body = []
            out.append(rl)
            i += 1
            while i < len(lines):
                brl = lines[i]
                bline = _strip_comment(brl.text).strip()
                if bline.startswith('%macro'):
                    raise AsmError(brl.filename, brl.lineno,
                                   "nested %macro definition is not allowed")
                if bline == '%endm':
                    out.append(brl)
                    break
                body.append(brl)
                out.append(brl)
                i += 1
            else:
                raise AsmError(def_filename, def_lineno,
                               f"unterminated %macro '{macro_name}': missing %endm")
            macro_table[macro_name] = MacroDef(
                params=params, body=body,
                def_filename=def_filename, def_lineno=def_lineno)
            i += 1

        elif line == '%endm':
            raise AsmError(rl.filename, rl.lineno,
                           "unexpected %endm without matching %macro")
        else:
            out.append(rl)
            i += 1

    return out, macro_table


def expand_macros(lines: list, macro_table: dict, _expanding=None) -> list:
    """Stage 3: replace macro invocations with expanded bodies.
    Recursively expands nested macro calls; detects recursive cycles via _expanding."""
    if _expanding is None:
        _expanding = frozenset()
    out = []
    for rl in lines:
        line = _strip_comment(rl.text).strip()
        if not line:
            out.append(rl)
            continue

        tok = _tokenize_line(rl.filename, rl.lineno, line)
        first_token = tok.mnemonic if tok else ''
        if first_token not in macro_table:
            out.append(rl)
            continue

        macro_name = first_token
        mdef = macro_table[macro_name]

        if macro_name in _expanding:
            raise AsmError(rl.filename, rl.lineno,
                           f"recursive macro expansion of '{macro_name}'")

        args_str = tok.operands_str
        label_prefix = (' '.join(f'{l}:' for l in tok.labels) + ' '
                        if tok.labels else '')
        args = [a.strip() for a in args_str.split(',')] if args_str else []
        if len(args) != len(mdef.params):
            raise AsmError(rl.filename, rl.lineno,
                           f"macro '{macro_name}' expects {len(mdef.params)} "
                           f"argument(s), got {len(args)}")

        out.append(RawLine(rl.filename, rl.lineno, f"; %expand {line}"))

        subst = dict(zip(mdef.params, args))
        expanded_body = []
        first_nonempty = True
        for brl in mdef.body:
            bline = _strip_comment(brl.text).strip()
            if not bline:
                expanded_body.append(RawLine(mdef.def_filename, brl.lineno, brl.text))
                continue
            expanded = bline
            for param, arg in subst.items():
                if param.startswith('%'):
                    # Positional param (%1, %2, ...): replace %N not followed by digit
                    expanded = re.sub(re.escape(param) + r'(?!\d)', arg, expanded)
                else:
                    # Named param: use word boundaries
                    expanded = re.sub(r'\b' + re.escape(param) + r'\b', arg, expanded)
            if first_nonempty and label_prefix:
                expanded = label_prefix + ' ' + expanded
                first_nonempty = False
            elif first_nonempty:
                first_nonempty = False
            expanded_body.append(RawLine(mdef.def_filename, brl.lineno, expanded))

        out.extend(expand_macros(expanded_body, macro_table, _expanding | {macro_name}))

    return out


def strip_lines(raw_lines: list) -> list:
    """Transition stage: RawLine → SourceLine.
    Strips comments, assigns source_index; skips blank lines, macro def blocks, %include lines.
    %define lines pass through; collect_defines removes them in the next stage."""
    out = []
    in_macro_def = False
    for source_index, rl in enumerate(raw_lines):
        line = _strip_comment(rl.text).strip()
        if line.startswith('%macro'):
            in_macro_def = True
            continue
        if line == '%endm':
            in_macro_def = False
            continue
        if in_macro_def:
            continue
        if re.match(r'%include\s+', line):
            continue
        if not line:
            continue
        out.append(SourceLine(rl.filename, rl.lineno, line, source_index))
    return out


def collect_defines(lines: list) -> tuple:
    """Stage 4: extract %define directives.
    Returns (remaining_lines, define_table).
    %define lines are consumed; all other SourceLines pass through."""
    out = []
    define_table = {}
    for sl in lines:
        m = re.match(r'%define\s+(\w+)\s+(.*)', sl.text)
        if m:
            define_table[m.group(1)] = m.group(2).strip()
        else:
            out.append(sl)
    return out, define_table


def filter_conditionals(lines: list, define_table: dict) -> list:
    """Stage 5: apply %ifdef/%ifeq/%ifneq/%endif conditional filtering.
    Stack frames: (active: bool, open_filename: str, open_lineno: int)."""
    out = []
    stack = []

    for sl in lines:
        line = sl.text

        if re.match(r'%ifdef\b', line):
            m = re.match(r'%ifdef\s+(\w+)\s*$', line)
            if not m:
                raise AsmError(sl.filename, sl.lineno, "malformed %ifdef directive")
            stack.append((m.group(1) in define_table, sl.filename, sl.lineno))
            continue

        bad = re.match(r'(%ifeq|%ifneq)\b(.*)', line)
        if bad:
            directive = bad.group(1)
            operands = bad.group(2)
            for name, val in define_table.items():
                operands = re.sub(r'\b' + re.escape(name) + r'\b', val, operands)
            tokens = operands.split()
            if len(tokens) != 2:
                raise AsmError(sl.filename, sl.lineno,
                    f"{directive} requires exactly 2 operands, got {len(tokens)}")
            a_val = _eval_expr(tokens[0], {}, sl.filename, sl.lineno)
            b_val = _eval_expr(tokens[1], {}, sl.filename, sl.lineno)
            result = (a_val == b_val) if directive == '%ifeq' else (a_val != b_val)
            stack.append((result, sl.filename, sl.lineno))
            continue

        if re.match(r'%endif\s*$', line):
            if not stack:
                raise AsmError(sl.filename, sl.lineno,
                    "%endif without matching %ifdef/%ifeq/%ifneq")
            stack.pop()
            continue

        if all(frame[0] for frame in stack):
            out.append(sl)

    if stack:
        open_fn, open_ln = stack[0][1], stack[0][2]
        raise AsmError(open_fn, open_ln,
            "unterminated %ifdef/%ifeq/%ifneq: missing %endif")

    return out


def substitute(lines: list, define_table: dict) -> list:
    """Stage 6: whole-word text substitution of all %define names."""
    out = []
    for sl in lines:
        text = sl.text
        for name, val in define_table.items():
            text = re.sub(r'\b' + re.escape(name) + r'\b', val, text)
        out.append(SourceLine(sl.filename, sl.lineno, text, sl.source_index))
    return out


def _split_comma_nonempty(ops: str) -> list[str]:
    """Like Haskell ``splitComma`` / ``delta`` operand splitting."""
    if not ops or not ops.strip():
        return []
    return [x.strip() for x in ops.split(",")]


def _is_linkage_directive(mnem: str) -> bool:
    m = mnem.lower().strip()
    return m in (".global", ".globl", ".local")


def group_contig_by_section(stmts: list) -> list[list]:
    """``groupContigBySection`` from Layout.hs — split runs with the same ``section``."""
    if not stmts:
        return []
    out = []
    cur_sec = getattr(stmts[0], "section", "text")
    chunk: list = []
    for s in stmts:
        sec = getattr(s, "section", "text")
        if sec == cur_sec:
            chunk.append(s)
        else:
            out.append(chunk)
            chunk = [s]
            cur_sec = sec
    if chunk:
        out.append(chunk)
    return out


def assign_addresses(lines: list, *, object_layout: bool = False) -> tuple:
    """Stage 7: tokenize SourceLines, collect labels, assign word addresses.

    Matches ``assignAddresses`` / ``RRISC.Asm.Layout`` (single linear ``addr``,
    ``.section`` switches section without resetting ``addr``, ``.org`` does not
    emit a statement).

    When ``object_layout`` is True, ``.base`` is rejected like ``ras`` (flat mode
    may still use ``.base`` for register-relative addressing).
    """
    addr = 0
    cur_sec = "text"
    stmts = []
    labels = {}

    for sl in lines:
        stmt = _tokenize_line(sl.filename, sl.lineno, sl.text, sl.source_index)
        if stmt is None:
            continue

        mnem_raw = stmt.mnemonic
        mnem = mnem_raw

        if mnem == ".section":
            name = stmt.operands_str.strip()
            if not name:
                raise AsmError(sl.filename, sl.lineno, ".section requires a section name")
            stmt.addr = addr
            stmt.section = name
            stmts.append(stmt)
            cur_sec = name
            continue

        stmt.section = cur_sec
        stmt.addr = addr

        for label in stmt.labels:
            if label in labels:
                raise AsmError(sl.filename, sl.lineno, f"duplicate label '{label}'")
            labels[label] = addr

        if not mnem_raw:
            stmts.append(stmt)
            continue

        if mnem == ".org":
            ops = stmt.operands_str
            if not ops.strip():
                raise AsmError(sl.filename, sl.lineno, ".org requires an address")
            addr = _eval_expr(ops, labels, sl.filename, sl.lineno)
            if not 0 <= addr <= WORD_MASK:
                raise AsmError(
                    sl.filename,
                    sl.lineno,
                    f".org address {addr} out of range (0..{WORD_MASK})",
                )
            continue

        if mnem == ".align":
            ops = stmt.operands_str
            if not ops.strip():
                raise AsmError(sl.filename, sl.lineno, ".align requires an argument")
            align = _eval_expr(ops.strip(), labels, sl.filename, sl.lineno)
            if align < 1:
                raise AsmError(
                    sl.filename,
                    sl.lineno,
                    f".align argument {align} must be >= 1",
                )
            stmts.append(stmt)
            addr = (addr + align - 1) // align * align
            continue

        if _is_linkage_directive(mnem_raw):
            stmts.append(stmt)
            continue

        stmts.append(stmt)

        ops = stmt.operands_str

        if object_layout and mnem == ".base":
            raise AsmError(
                sl.filename,
                sl.lineno,
                "'.base' is not supported by this assembler",
            )

        if mnem == "li":
            addr += 2
        elif mnem == ".word":
            parts = _split_comma_nonempty(ops)
            addr += max(1, len(parts))
        elif mnem == ".float":
            parts = _split_comma_nonempty(ops)
            addr += max(1, len(parts)) * 4
        elif mnem == ".sixbit":
            addr += len(_parse_string_literal(ops, sl.filename, sl.lineno))
        elif mnem == ".str":
            s = _parse_string_literal(ops, sl.filename, sl.lineno)
            addr += len("".join(s).encode("utf-8"))
        elif mnem == ".strz":
            s = _parse_string_literal(ops, sl.filename, sl.lineno)
            addr += 1 + len("".join(s).encode("utf-8"))
        elif mnem == ".fill":
            count_str = ops.split(",")[0].strip() if ops else ""
            if not count_str:
                raise AsmError(sl.filename, sl.lineno, ".fill requires a count")
            count = _eval_expr(count_str, labels, sl.filename, sl.lineno)
            if count < 0:
                raise AsmError(
                    sl.filename,
                    sl.lineno,
                    f".fill count {count} must be non-negative",
                )
            addr += count
        elif mnem == ".base":
            pass
        elif mnem == "or":
            addr += 3
        elif mnem == "xor":
            addr += 4
        else:
            addr += 1

    return stmts, labels

# -- assembler --

class Assembler:
    def __init__(self, filename, include_dirs=()):
        self.filename = filename
        self.include_dirs = include_dirs
        self.macros = {}          # name -> replacement text (%define)
        self.param_macros = {}    # name -> MacroDef (%macro)
        self.labels = {}          # name -> word address
        self.listing_entries = [] # [(source_index, addr, word)]
        self._flat_lines = []     # list[RawLine] -- full flattened source for listing
        self.bases = {0: 0, 7: 0o7777}  # reg -> declared base value; r0/r7 are hardwired

    def assemble(self, source):
        raw = expand_includes(source, self.filename,
                              frozenset({os.path.normpath(os.path.abspath(self.filename))})
                              if self.filename else frozenset(),
                              self.include_dirs)
        raw, self.param_macros = collect_macro_defs(raw)
        raw = expand_macros(raw, self.param_macros)
        self._flat_lines = raw

        lines = strip_lines(raw)
        lines, self.macros = collect_defines(lines)
        lines = filter_conditionals(lines, self.macros)
        lines = substitute(lines, self.macros)

        stmts, self.labels = assign_addresses(lines)
        stmts, self.labels = self._relax_branches(stmts)
        return self._encode_all(stmts)

    def assemble_object(self, source, cli_defines=None):
        """Emit a relocatable ``ObjectFile`` (``assembleFileToObject`` / no branch relaxation)."""
        from .asm_obj_emit import encode_to_object

        cli_defines = dict(cli_defines or {})
        raw = expand_includes(
            source,
            self.filename,
            frozenset({os.path.normpath(os.path.abspath(self.filename))})
            if self.filename
            else frozenset(),
            self.include_dirs,
        )
        raw, self.param_macros = collect_macro_defs(raw)
        raw = expand_macros(raw, self.param_macros)
        self._flat_lines = raw

        lines = strip_lines(raw)
        lines, self.macros = collect_defines(lines)
        self.macros.update(cli_defines)
        lines = filter_conditionals(lines, self.macros)
        lines = substitute(lines, self.macros)

        stmts, self.labels = assign_addresses(lines, object_layout=True)
        return encode_to_object(stmts, self._flat_lines, self)

    # -- branch relaxation --

    def _stmt_size(self, stmt) -> int:
        mnem = stmt.mnemonic
        ops  = stmt.operands_str
        f, n = stmt.filename, stmt.lineno
        if mnem in ('', '.base', '.align', '.section') or mnem.lower() in ('.global', '.globl', '.local'):
            return 0
        if mnem == 'li':
            return 2
        if mnem == '.word':
            parts = _split_comma_nonempty(ops)
            return max(1, len(parts))
        if mnem == '.float':
            parts = _split_comma_nonempty(ops)
            return max(1, len(parts)) * 4
        if mnem == '.sixbit':
            try: return len(_parse_string_literal(ops, f, n))
            except Exception: return 0
        if mnem == '.str':
            try:
                s = _parse_string_literal(ops, f, n)
                return len(''.join(s).encode('utf-8'))
            except Exception: return 0
        if mnem == '.strz':
            try:
                s = _parse_string_literal(ops, f, n)
                return 1 + len(''.join(s).encode('utf-8'))
            except Exception: return 0
        if mnem == '.fill':
            count_str = ops.split(',')[0].strip() if ops else ''
            if not count_str: return 0
            try: return max(0, _eval_expr(count_str, {}, f, n))
            except Exception: return 0
        if mnem == 'or':
            return 3
        if mnem == 'xor':
            return 4
        return 1

    def _labels_from_stmts(self, stmts) -> dict:
        labels = {}
        for stmt in stmts:
            for label in stmt.labels:
                labels[label] = stmt.addr
        return labels

    def _recompute_stmt_addrs(self, stmts):
        """Recompute addresses after branch relaxation inserts instructions.

        Statements keep their pre-relaxation ``stmt.addr`` unless patched to -1.
        Forward jumps in that original placement (from ``.org``, alignment, etc.)
        must be preserved; the old heuristic ``abs(...) > 100`` broke common
        gaps such as ``.org 0o100`` (64 words), collapsing crt0 to address 0.
        """
        addr = 0
        for stmt in stmts:
            if stmt.addr != -1 and stmt.addr > addr:
                addr = stmt.addr
            stmt.addr = addr
            addr += self._stmt_size(stmt)

    def _relax_branches(self, stmts):
        chunks = group_contig_by_section(stmts)
        merged: list = []
        for ch in chunks:
            merged.extend(self._relax_branches_chunk(ch))
        return merged, self._labels_from_stmts(merged)

    def _relax_branches_chunk(self, stmts):
        stmts = list(stmts)
        skip_n = 0
        for _iteration in range(20):
            labels = self._labels_from_stmts(stmts)
            violations = [
                i
                for i, s in enumerate(stmts)
                if s.mnemonic in ("bt", "bf")
                and re.fullmatch(r"[A-Za-z_]\w*", s.operands_str.strip())
                and s.operands_str.strip() in labels
                and not (-64 <= labels[s.operands_str.strip()] - s.addr <= 63)
            ]
            if not violations:
                break
            for i in reversed(violations):
                stmt = stmts[i]
                target = stmt.operands_str.strip()
                skip_lbl = f"__br_{skip_n}"
                skip_n += 1
                inv = "bf" if stmt.mnemonic == "bt" else "bt"
                f, ln, si = stmt.filename, stmt.lineno, stmt.source_index
                sec = getattr(stmt, "section", "text")
                stmts[i : i + 1] = [
                    Statement(
                        f,
                        ln,
                        list(stmt.labels),
                        inv,
                        skip_lbl,
                        addr=-1,
                        source_index=si,
                        section=sec,
                    ),
                    Statement(
                        f,
                        ln,
                        [],
                        "li",
                        f"r4, {target}",
                        addr=-1,
                        source_index=si,
                        section=sec,
                    ),
                    Statement(
                        f,
                        ln,
                        [],
                        "jalr",
                        "r0, r4",
                        addr=-1,
                        source_index=si,
                        section=sec,
                    ),
                    Statement(
                        f,
                        ln,
                        [skip_lbl],
                        "",
                        "",
                        addr=-1,
                        source_index=si,
                        section=sec,
                    ),
                ]
            self._recompute_stmt_addrs(stmts)
        return stmts

    # -- encoding --

    def _encode_all(self, stmts):
        self.bases = {0: 0, 7: 0o7777}
        if not stmts:
            return []
        word_map = {}
        for stmt in stmts:
            w = self._encode(stmt)
            if isinstance(w, list):
                for i, ww in enumerate(w):
                    word_map[stmt.addr + i] = ww
                    self.listing_entries.append((stmt.source_index, stmt.addr + i, ww))
            else:
                word_map[stmt.addr] = w
                self.listing_entries.append((stmt.source_index, stmt.addr, w))
        max_addr = max(word_map)
        result = [0] * (max_addr + 1)
        for a, w in word_map.items():
            result[a] = w
        return result

    def _encode(self, stmt: Statement):
        mnem    = stmt.mnemonic
        ops_str = stmt.operands_str
        ops     = [o.strip() for o in ops_str.split(',')] if ops_str else []
        f, n    = stmt.filename, stmt.lineno
        addr    = stmt.addr

        if mnem.lower() in ('.global', '.globl', '.local', '.section'):
            return []

        match mnem:
            case 'nop':
                self._expect(ops, 0, mnem, f, n)
                return 0o0000
            case 'clrt':
                self._expect(ops, 0, mnem, f, n)
                return 0o3000
            case 'halt':
                self._expect(ops, 0, mnem, f, n)
                return 0o7777

            case '.base':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd in (0, 7):
                    raise AsmError(f, n, f"cannot redeclare base for hardwired r{rd}")
                val = _eval_expr(ops[1], self.labels, f, n)
                if not 0 <= val <= WORD_MASK:
                    raise AsmError(f, n, f"base value {val} out of 12-bit range")
                self.bases[rd] = val
                return []

            case '.word':
                if not ops:
                    raise AsmError(f, n, ".word requires a value")
                words = [_eval_expr(v, self.labels, f, n) & WORD_MASK for v in ops]
                return words[0] if len(words) == 1 else words

            case '.sixbit':
                s = _parse_string_literal(ops_str.strip(), f, n)
                result = []
                for ch in s:
                    v = encode_sixbit(ch)
                    if v is None:
                        raise AsmError(f, n, f"character {ch!r} has no SIXBIT representation")
                    result.append(v)
                return result if len(result) != 1 else result[0]

            case '.str':
                s = _parse_string_literal(ops_str.strip(), f, n)
                result = list(''.join(s).encode('utf-8'))
                return result if len(result) != 1 else result[0]

            case '.strz':
                s = _parse_string_literal(ops_str.strip(), f, n)
                result = list(''.join(s).encode('utf-8')) + [0]
                return result if len(result) != 1 else result[0]

            case '.float':
                if not ops:
                    raise AsmError(f, n, ".float requires a value")
                result = []
                for v in ops:
                    try:
                        result.extend(from_float(float(v)))
                    except ValueError:
                        raise AsmError(f, n, f"invalid float literal '{v.strip()}'")
                return result

            case '.fill':
                if not ops:
                    raise AsmError(f, n, ".fill requires a count")
                if len(ops) > 2:
                    raise AsmError(f, n, f".fill takes at most 2 operands, got {len(ops)}")
                count = _eval_expr(ops[0], self.labels, f, n)
                if count < 0:
                    raise AsmError(f, n, f".fill count {count} must be non-negative")
                val = _eval_expr(ops[1], self.labels, f, n) & WORD_MASK if len(ops) > 1 else 0
                return [val] * count

            case '.align':
                if not ops_str.strip():
                    raise AsmError(f, n, ".align requires an argument")
                align = _eval_expr(ops_str.strip(), self.labels, f, n)
                if align < 1:
                    raise AsmError(f, n, f".align argument {align} must be >= 1")
                return [0] * ((-addr) % align)

            case 'and':
                self._expect(ops, 3, mnem, f, n)
                return encode_r3(OP_AND, _reg(ops[0],f,n), _reg(ops[1],f,n), _reg(ops[2],f,n))
            case 'add':
                self._expect(ops, 3, mnem, f, n)
                return encode_r3(OP_ADD, _reg(ops[0],f,n), _reg(ops[1],f,n), _reg(ops[2],f,n))
            case 'addc':
                self._expect(ops, 3, mnem, f, n)
                return encode_r3(OP_ADDC, _reg(ops[0],f,n), _reg(ops[1],f,n), _reg(ops[2],f,n))
            case 'sub':
                self._expect(ops, 3, mnem, f, n)
                return encode_r3(OP_SUB, _reg(ops[0],f,n), _reg(ops[1],f,n), _reg(ops[2],f,n))

            case 'lui':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "lui cannot target r0 (use bf for branches)")
                if rd == 7:
                    raise AsmError(f, n, "lui cannot target r7 (use bf for branches)")
                return encode_ri(OP_LUI, rd, _imm6(_eval_expr(ops[1], self.labels, f, n), f, n))

            case 'addi':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "addi cannot target r0 (use bt for branches)")
                if rd == 7:
                    raise AsmError(f, n, "addi cannot target r7 (use bt for branches)")
                return encode_ri(OP_ADDI, rd, _imm6(_eval_expr(ops[1], self.labels, f, n), f, n))

            case 'subi':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "subi cannot target r0")
                if rd == 7:
                    raise AsmError(f, n, "subi cannot target r7")
                return encode_ri(OP_SUBI, rd, _imm6(_eval_expr(ops[1], self.labels, f, n), f, n))

            case 'bf':
                self._expect(ops, 1, mnem, f, n)
                off = self._branch_operand(ops[0], addr, f, n)
                rd = 7 if off < 0 else 0
                return encode_ri(OP_LUI, rd, off & IMM6_MASK)

            case 'bt':
                self._expect(ops, 1, mnem, f, n)
                off = self._branch_operand(ops[0], addr, f, n)
                rd = 7 if off < 0 else 0
                return encode_ri(OP_ADDI, rd, off & IMM6_MASK)

            case 'jalr' | 'ror' | 'rol' | 'lwr' | 'swr':
                self._expect(ops, 2, mnem, f, n)
                rb = {'jalr': RB_JALR, 'ror': RB_ROR, 'rol': RB_ROL,
                      'lwr': RB_LWR, 'swr': RB_SWR}[mnem]
                return encode_r3(OP_SPEC, _reg(ops[0],f,n), _reg(ops[1],f,n), rb)

            case 'lw' | 'sw':
                raise AsmError(f, n, f"'{mnem}' is not part of this ISA; use lwr/swr (register-addressed)")

            case 'li':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "li cannot target r0")
                val = _eval_expr(ops[1], self.labels, f, n)
                if val < -2048 or val > WORD_MASK:
                    raise AsmError(f, n, f"li value {val} out of 12-bit range")
                val &= WORD_MASK
                lower = val & IMM6_MASK   # bits 5:0  (0..63)
                upper = (val >> 6) & IMM6_MASK  # bits 11:6 (0..63)
                # addi is now unsigned (0..63), no sign-extension compensation needed
                return [encode_ri(OP_LUI, rd, upper), encode_ri(OP_ADDI, rd, lower)]

            case '':
                return []

            # -- synthetic instructions --

            case 'mov':
                self._expect(ops, 2, mnem, f, n)
                return encode_r3(OP_AND, _reg(ops[0],f,n), _reg(ops[1],f,n), 7)

            case 'clr':
                self._expect(ops, 1, mnem, f, n)
                return encode_r3(OP_AND, _reg(ops[0],f,n), 0, 0)

            case 'neg':
                self._expect(ops, 2, mnem, f, n)
                return encode_r3(OP_SUB, _reg(ops[0],f,n), 0, _reg(ops[1],f,n))

            case 'not':
                self._expect(ops, 2, mnem, f, n)
                return encode_r3(OP_SUB, _reg(ops[0],f,n), 7, _reg(ops[1],f,n))

            case 'ret':
                self._expect(ops, 0, mnem, f, n)
                return encode_r3(OP_SPEC, 0, 5, RB_JALR)

            case 'test':
                self._expect(ops, 1, mnem, f, n)
                return encode_r3(OP_SUB, 0, 0, _reg(ops[0],f,n))

            case 'set':
                self._expect(ops, 0, mnem, f, n)
                return encode_r3(OP_SUB, 0, 0, 7)

            case 'or':
                self._expect(ops, 3, mnem, f, n)
                rx = _reg(ops[0], f, n)
                ry = _reg(ops[1], f, n)
                rz = _reg(ops[2], f, n)
                if rx == 4:
                    raise AsmError(f, n, "or: destination cannot be r4 (assembler scratch)")
                return [
                    encode_r3(OP_AND, 4,  ry, rz),
                    encode_r3(OP_ADD, rx, ry, rz),
                    encode_r3(OP_SUB, rx, rx, 4),
                ]

            case 'xor':
                self._expect(ops, 3, mnem, f, n)
                rx = _reg(ops[0], f, n)
                ry = _reg(ops[1], f, n)
                rz = _reg(ops[2], f, n)
                if rx == 4:
                    raise AsmError(f, n, "xor: destination cannot be r4 (assembler scratch)")
                return [
                    encode_r3(OP_AND, 4,  ry, rz),
                    encode_r3(OP_ADD, rx, ry, rz),
                    encode_r3(OP_SUB, rx, rx, 4),
                    encode_r3(OP_SUB, rx, rx, 4),
                ]

            case _:
                raise AsmError(f, n, f"unknown mnemonic '{mnem}'")

    def _branch_operand(self, operand, instr_addr, filename, lineno):
        """Resolve branch operand to a signed offset in -64..63."""
        if re.fullmatch(r'[A-Za-z_]\w*', operand):
            if operand not in self.labels:
                raise AsmError(filename, lineno, f"undefined label '{operand}'")
            offset = self.labels[operand] - instr_addr
        else:
            offset = _eval_expr(operand, self.labels, filename, lineno)
        if offset < -64 or offset > 63:
            raise AsmError(filename, lineno,
                f"branch offset {offset:+d} out of range (-64..63)")
        return offset

    @staticmethod
    def _expect(ops, n, mnem, filename, lineno):
        if len(ops) != n:
            raise AsmError(filename, lineno,
                f"'{mnem}' expects {n} operand(s), got {len(ops)}")

# -- binary output --

def write_binary(words, path):
    with open(path, 'wb') as f:
        for w in words:
            w &= WORD_MASK
            f.write(bytes([w & 0xFF, (w >> 8) & 0x0F]))

def write_readmemb(words, path):
    with open(path, 'w') as f:
        for w in words:
            f.write(f'{w & WORD_MASK:012b}\n')

# -- listing --

def format_listing(flat_lines, listing_entries):
    """Format an assembly listing, emitting a file header whenever the source file changes."""
    by_loc = {}
    for line_idx, addr, word in listing_entries:
        by_loc.setdefault(line_idx, []).append((addr, word))

    out = []
    prev_file = None
    seen_files = set()
    for line_idx, (fn, ln, raw) in enumerate(flat_lines):
        if fn != prev_file:
            disp = os.path.relpath(fn)
            tag  = ' (continued)' if fn in seen_files else ''
            out.append(f"; ==== {disp}{tag} ====")
            seen_files.add(fn)
            prev_file = fn
        entries = by_loc.get(line_idx, [])
        ln_str = f"{ln:4d}"
        if entries:
            addr, word = entries[0]
            out.append(f"{ln_str}  {addr:04o}  {word:04o}  {raw}")
            for addr, word in entries[1:]:
                out.append(f"      {addr:04o}  {word:04o}")
        else:
            out.append(f"{ln_str}              {raw}")
    return "\n".join(out)

# -- main --

def main():
    print(
        "pytools.asm: deprecated: use `python -m pytools.pyras --format bin …` "
        "(flat assembly) or the Haskell `ras` binary for relocatable `.o`.",
        file=sys.stderr,
    )
    parser = argparse.ArgumentParser(description='RRISC assembler')
    parser.add_argument('source', help='input .asm file')
    parser.add_argument('-o', '--output', help='output file (default: <source>.bin or .mem)')
    parser.add_argument('-I', dest='include_dirs', metavar='DIR', action='append', default=[],
                        help='add directory to include search path (may repeat)')
    parser.add_argument('--format', choices=['bin', 'readmemb'], default='bin',
                        help='output format: bin (raw binary) or readmemb (Verilog $readmemb text)')
    parser.add_argument('--list', action='store_true', help='print assembly listing to stdout')
    args = parser.parse_args()

    default_ext = '.mem' if args.format == 'readmemb' else '.bin'
    out = args.output or (re.sub(r'(\.\w+)?$', default_ext, args.source, count=1))

    try:
        with open(args.source, encoding='utf-8') as f:
            source = f.read()
    except UnicodeDecodeError:
        print(f"pytools.asm: {args.source}: not a text file", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"pytools.asm: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        asm = Assembler(args.source, include_dirs=args.include_dirs)
        words = asm.assemble(source)
        if args.format == 'readmemb':
            write_readmemb(words, out)
        else:
            write_binary(words, out)
        if args.list:
            print(format_listing(asm._flat_lines, asm.listing_entries))
    except AsmError as e:
        print(e, file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
