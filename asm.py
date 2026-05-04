#!/usr/bin/env python3
"""asm.py -- RRISC flat assembler.

Usage: python asm.py input.asm [-o output.bin]

Source format:
  %define NAME value     simple text substitution
  %include "file.s"      splice another source file inline
  %macro NAME [p1, p2]   define a parameterized macro
  ...body...
  %endm
  label:                 label (standalone or inline before instruction)
  instruction ops        see Arch.md for full ISA
  ; comment              rest of line ignored
  .word value[, ...]     emit one raw 12-bit word per value
  .float value[, ...]   emit four 12-bit words (48-bit RRISC float) per value
  .fill count[, value]   emit count words of value (default 0)
  .align n               advance address to next multiple of n
  .unicode "string"      emit UTF-8 bytes of string, one byte per word
  .org address           set current address counter
  .octal                 set default number radix to 8 (bare literals parsed as octal)
  .decimal               set default number radix to 10 (bare literals parsed as decimal)
"""

import argparse
import os
import re
import sys
from collections import namedtuple
from dataclasses import dataclass, field

from isa import (OP_ADDI, OP_LUI, OP_AND, OP_LW, OP_ADDC, OP_SUB, OP_SW, OP_SPEC,
                 RB_JALR, RB_ROR, RB_ROL, RB_LWR, RB_SWR,
                 encode_r3, encode_ri, WORD_MASK, IMM6_MASK)
from float48 import from_float
from sixbit import encode_sixbit

MacroDef = namedtuple('MacroDef', ['params', 'body', 'def_filename', 'def_lineno'])

@dataclass
class Statement:
    filename:     str
    lineno:       int
    labels:       list
    mnemonic:     str   # lowercased; '' for labels-only lines
    operands_str: str   # text after mnemonic, stripped; '' if none
    addr:         int = 0
    source_index: int = 0

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

def _eval_expr(s, labels, filename, lineno, radix=10):
    """Evaluate an integer expression; supports + - * / % & | ^ ~ << >> and ().
    Label names resolve via labels dict.  Result is masked to WORD_MASK (12 bits).
    radix sets the default base for bare integer literals; explicit 0x/0o/0b prefixes
    always override it."""
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
                if len(tok) > 2 and tok[1:2].lower() in ('x', 'o', 'b'):
                    return int(tok, 0)
                return int(tok, radix)
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
    """Encode val as 6-bit field; accepts -32..63 (signed or unsigned 6-bit)."""
    if val < -32 or val > 63:
        raise AsmError(filename, lineno, f"immediate {val} out of 6-bit range (-32..63)")
    return val & IMM6_MASK

def _resolve_mem_operand(val, rd, bases, filename, lineno):
    """Resolve a lw/sw address operand to a 6-bit offset.

    If val fits in 6 bits (-32..63) it is used directly.  If val is a valid
    12-bit address (64..0o7777) the assembler checks that rD has a declared base
    whose page (upper 6 bits) matches and extracts the lower 6 bits as the offset.
    """
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

# -- assembler --

class Assembler:
    def __init__(self, filename):
        self.filename = filename
        self.macros = {}          # name -> replacement text (%define)
        self.param_macros = {}    # name -> MacroDef (%macro)
        self.labels = {}          # name -> word address
        self.listing_entries = [] # [(source_index, addr, word)]
        self._flat_lines = []     # [(filename, lineno, raw)] -- full flattened source for listing
        self.radix = 10           # default number base; changed by .octal / .decimal
        self.bases = {0: 0, 7: 0o7777}  # reg -> declared base value; r0/r7 are hardwired

    def assemble(self, source):
        stmts = self._preprocess(source)
        return self._encode_all(stmts)

    # -- preprocessing: macros, labels, address assignment --

    def _expand_includes(self, source, src_path, seen):
        """Recursively splice %include "path" directives.
        Returns list of (abs_filename, lineno, raw_line).
        The %include directive line itself is preserved so it appears in the listing."""
        src_path = os.path.normpath(os.path.abspath(src_path)) if src_path else self.filename
        src_dir  = os.path.dirname(src_path)
        out = []
        for lineno, raw in enumerate(source.splitlines(), 1):
            line = _strip_comment(raw).strip()
            m = re.match(r'%include\s+"([^"]+)"\s*$', line)
            if m:
                out.append((src_path, lineno, raw))  # keep in listing, skipped by Pass A
                inc_rel  = m.group(1)
                inc_path = inc_rel if os.path.isabs(inc_rel) else os.path.join(src_dir, inc_rel)
                inc_path = os.path.normpath(inc_path)
                if inc_path in seen:
                    raise AsmError(src_path, lineno, f"circular %include of '{inc_rel}'")
                try:
                    with open(inc_path, encoding='utf-8') as fh:
                        inc_source = fh.read()
                except OSError as e:
                    raise AsmError(src_path, lineno,
                                   f"cannot open included file '{inc_rel}': {e}")
                out.extend(self._expand_includes(inc_source, inc_path, seen | {inc_path}))
            else:
                out.append((src_path, lineno, raw))
        return out

    def _collect_macro_defs(self, lines):
        """Scan flattened lines for %macro/%endm blocks, store in self.param_macros.
        Returns all lines; definition lines are kept for listing but skipped during assembly."""
        out = []
        i = 0
        while i < len(lines):
            filename, lineno, raw = lines[i]
            line = _strip_comment(raw).strip()

            if line.startswith('%macro'):
                m = re.match(r'%macro\s+(\w+)\s*(.*)', line)
                if not m:
                    raise AsmError(filename, lineno, "malformed %macro directive")
                macro_name = m.group(1)
                params_str = m.group(2).strip()
                params = [p.strip() for p in params_str.split(',')] if params_str else []
                for p in params:
                    if not re.fullmatch(r'[A-Za-z_]\w*', p):
                        raise AsmError(filename, lineno,
                                       f"invalid parameter name '{p}' in %macro {macro_name}")
                if macro_name in self.param_macros:
                    raise AsmError(filename, lineno, f"redefinition of macro '{macro_name}'")
                def_filename, def_lineno = filename, lineno
                body = []
                out.append(lines[i])  # keep %macro line for listing
                i += 1
                while i < len(lines):
                    bfn, bln, braw = lines[i]
                    bline = _strip_comment(braw).strip()
                    if bline.startswith('%macro'):
                        raise AsmError(bfn, bln, "nested %macro definition is not allowed")
                    if bline == '%endm':
                        out.append(lines[i])  # keep %endm line for listing
                        break
                    body.append((bln, braw))
                    out.append(lines[i])  # keep body line for listing
                    i += 1
                else:
                    raise AsmError(def_filename, def_lineno,
                                   f"unterminated %macro '{macro_name}': missing %endm")
                self.param_macros[macro_name] = MacroDef(
                    params=params, body=body,
                    def_filename=def_filename, def_lineno=def_lineno)
                i += 1  # skip past %endm (already appended above)

            elif line == '%endm':
                raise AsmError(filename, lineno, "unexpected %endm without matching %macro")

            else:
                out.append(lines[i])
                i += 1

        return out

    def _expand_macros(self, lines, _expanding=None):
        """Replace macro invocations with their expanded bodies.
        Recursively expands nested macro calls; detects recursive cycles via _expanding."""
        if _expanding is None:
            _expanding = frozenset()
        out = []
        for filename, lineno, raw in lines:
            line = _strip_comment(raw).strip()
            if not line:
                out.append((filename, lineno, raw))
                continue

            tok = _tokenize_line(filename, lineno, line)
            first_token = tok.mnemonic if tok else ''
            if first_token not in self.param_macros:
                out.append((filename, lineno, raw))
                continue

            macro_name = first_token
            mdef = self.param_macros[macro_name]

            if macro_name in _expanding:
                raise AsmError(filename, lineno,
                               f"recursive macro expansion of '{macro_name}'")

            args_str = tok.operands_str
            label_prefix = (' '.join(f'{l}:' for l in tok.labels) + ' '
                            if tok.labels else '')
            args = [a.strip() for a in args_str.split(',')] if args_str else []
            if len(args) != len(mdef.params):
                raise AsmError(filename, lineno,
                               f"macro '{macro_name}' expects {len(mdef.params)} "
                               f"argument(s), got {len(args)}")

            # Comment header shows the original invocation in the listing
            out.append((filename, lineno, f"; %expand {line}"))

            subst = dict(zip(mdef.params, args))
            expanded_body = []
            first_nonempty = True
            for def_bln, braw in mdef.body:
                bline = _strip_comment(braw).strip()
                if not bline:
                    expanded_body.append((mdef.def_filename, def_bln, braw))
                    continue
                expanded = bline
                for param, arg in subst.items():
                    expanded = re.sub(r'\b' + re.escape(param) + r'\b', arg, expanded)
                if first_nonempty and label_prefix:
                    expanded = label_prefix + ' ' + expanded
                    first_nonempty = False
                elif first_nonempty:
                    first_nonempty = False
                expanded_body.append((mdef.def_filename, def_bln, expanded))

            # Recursively expand any nested macro calls in the body
            out.extend(self._expand_macros(expanded_body, _expanding | {macro_name}))

        return out

    def _preprocess(self, source):
        """Return [Statement] for each encodable statement."""
        raw_lines = self._expand_includes(source, self.filename,
                                          {os.path.normpath(os.path.abspath(self.filename))}
                                          if self.filename else set())
        raw_lines = self._collect_macro_defs(raw_lines)
        raw_lines = self._expand_macros(raw_lines)
        self._flat_lines = raw_lines

        # Pass A: collect all %define macros; skip %include and macro-definition lines
        no_defines = []
        in_macro_def = False
        for source_index, (filename, lineno, raw) in enumerate(raw_lines):
            line = _strip_comment(raw).strip()
            if line.startswith('%macro'):
                in_macro_def = True
                continue  # in _flat_lines for listing; not assembled
            if line == '%endm':
                in_macro_def = False
                continue
            if in_macro_def:
                continue  # definition body: assembled only via expansion
            m = re.match(r'%define\s+(\w+)\s+(.*)', line)
            if m:
                name, val = m.group(1), m.group(2).strip()
                self.macros[name] = val
            elif re.match(r'%include\s+', line):
                pass  # already expanded; skip assembly
            elif line:
                no_defines.append((filename, lineno, line, source_index))

        # Pass C: process conditionals before substitution so %ifdef sees raw names
        no_defines = self._process_conditionals(no_defines)

        # Pass B: macro substitution (whole-word replacement)
        substituted = []
        for filename, lineno, line, source_index in no_defines:
            for name, val in self.macros.items():
                line = re.sub(r'\b' + re.escape(name) + r'\b', val, line)
            substituted.append((filename, lineno, line, source_index))

        return self._assign_addresses(substituted)

    def _process_conditionals(self, lines):
        """Pass C: filter lines through %ifdef/%ifeq/%ifneq/%endif.
        Called after Pass A (macros known) but before Pass B (substitution).
        %ifdef checks names directly; %ifeq/%ifneq substitute operands internally.
        lines is [(filename, lineno, text, source_index)].
        Stack frames are (active: bool, open_filename: str, open_lineno: int)."""
        out = []
        stack = []  # (active, filename, lineno) per open conditional

        for filename, lineno, line, source_index in lines:

            # %ifdef NAME
            if re.match(r'%ifdef\b', line):
                m = re.match(r'%ifdef\s+(\w+)\s*$', line)
                if not m:
                    raise AsmError(filename, lineno, "malformed %ifdef directive")
                stack.append((m.group(1) in self.macros, filename, lineno))
                continue

            # %ifeq / %ifneq — guard wrong operand count, then evaluate
            bad = re.match(r'(%ifeq|%ifneq)\b(.*)', line)
            if bad:
                directive = bad.group(1)
                operands = bad.group(2)
                for name, val in self.macros.items():
                    operands = re.sub(r'\b' + re.escape(name) + r'\b', val, operands)
                tokens = operands.split()
                if len(tokens) != 2:
                    raise AsmError(filename, lineno,
                        f"{directive} requires exactly 2 operands, got {len(tokens)}")
                a_val = _eval_expr(tokens[0], {}, filename, lineno)
                b_val = _eval_expr(tokens[1], {}, filename, lineno)
                result = (a_val == b_val) if directive == '%ifeq' else (a_val != b_val)
                stack.append((result, filename, lineno))
                continue

            # %endif
            if re.match(r'%endif\s*$', line):
                if not stack:
                    raise AsmError(filename, lineno,
                        "%endif without matching %ifdef/%ifeq/%ifneq")
                stack.pop()
                continue

            # ordinary line: emit only when all frames are active
            if all(frame[0] for frame in stack):
                out.append((filename, lineno, line, source_index))

        if stack:
            open_fn, open_ln = stack[0][1], stack[0][2]
            raise AsmError(open_fn, open_ln,
                "unterminated %ifdef/%ifeq/%ifneq: missing %endif")

        return out

    def _assign_addresses(self, substituted):
        """Tokenize lines, register labels, assign addresses. Returns [Statement]."""
        self.radix = 10
        addr = 0
        stmts = []
        for filename, lineno, line, source_index in substituted:
            stmt = _tokenize_line(filename, lineno, line, source_index)
            if stmt is None:
                continue

            for label in stmt.labels:
                if label in self.labels:
                    raise AsmError(filename, lineno, f"duplicate label '{label}'")
                self.labels[label] = addr

            if not stmt.mnemonic:
                continue  # labels-only line

            stmt.addr = addr
            mnem = stmt.mnemonic
            ops  = stmt.operands_str

            if mnem == '.org':
                if not ops:
                    raise AsmError(filename, lineno, ".org requires an address")
                addr = _eval_expr(ops, self.labels, filename, lineno, self.radix)
                if not 0 <= addr <= WORD_MASK:
                    raise AsmError(filename, lineno,
                                   f".org address {addr} out of range (0..{WORD_MASK})")
                continue  # .org emits no words

            if mnem in ('.decimal', '.octal'):
                self.radix = 10 if mnem == '.decimal' else 8
                stmts.append(stmt)
                continue  # emits no words, address unchanged

            stmts.append(stmt)

            if mnem == 'li':
                addr += 2
            elif mnem == '.word':
                addr += len(ops.split(',')) if ops else 1
            elif mnem == '.float':
                addr += (len(ops.split(',')) if ops else 1) * 4
            elif mnem == '.sixbit':
                addr += len(self._parse_string_literal(ops, filename, lineno))
            elif mnem == '.unicode':
                s = self._parse_string_literal(ops, filename, lineno)
                addr += len(''.join(s).encode('utf-8'))
            elif mnem == '.fill':
                count_str = ops.split(',')[0].strip() if ops else ''
                if not count_str:
                    raise AsmError(filename, lineno, ".fill requires a count")
                count = _eval_expr(count_str, self.labels, filename, lineno, self.radix)
                if count < 0:
                    raise AsmError(filename, lineno,
                                   f".fill count {count} must be non-negative")
                addr += count
            elif mnem == '.align':
                if not ops:
                    raise AsmError(filename, lineno, ".align requires an argument")
                align = _eval_expr(ops, self.labels, filename, lineno, self.radix)
                if align < 1:
                    raise AsmError(filename, lineno,
                                   f".align argument {align} must be >= 1")
                addr = (addr + align - 1) // align * align
            elif mnem == '.base':
                pass  # emits no words; validated and recorded in encoding pass
            else:
                addr += 1

        return stmts

    # -- encoding --

    def _encode_all(self, stmts):
        self.radix = 10
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

        match mnem:
            case 'nop':
                self._expect(ops, 0, mnem, f, n)
                return 0o0000
            case 'clrt':
                self._expect(ops, 0, mnem, f, n)
                return 0o6000
            case 'halt':
                self._expect(ops, 0, mnem, f, n)
                return 0o7777

            case '.decimal' | '.octal':
                self.radix = 10 if mnem == '.decimal' else 8
                return []

            case '.base':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd in (0, 7):
                    raise AsmError(f, n, f"cannot redeclare base for hardwired r{rd}")
                val = _eval_expr(ops[1], self.labels, f, n, self.radix)
                if not 0 <= val <= WORD_MASK:
                    raise AsmError(f, n, f"base value {val} out of 12-bit range")
                self.bases[rd] = val
                return []

            case '.word':
                if not ops:
                    raise AsmError(f, n, ".word requires a value")
                words = [_eval_expr(v, self.labels, f, n, self.radix) & WORD_MASK for v in ops]
                return words[0] if len(words) == 1 else words

            case '.sixbit':
                s = self._parse_string_literal(ops_str.strip(), f, n)
                result = []
                for ch in s:
                    v = encode_sixbit(ch)
                    if v is None:
                        raise AsmError(f, n, f"character {ch!r} has no SIXBIT representation")
                    result.append(v)
                return result if len(result) != 1 else result[0]

            case '.unicode':
                s = self._parse_string_literal(ops_str.strip(), f, n)
                result = list(''.join(s).encode('utf-8'))
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
                count = _eval_expr(ops[0], self.labels, f, n, self.radix)
                if count < 0:
                    raise AsmError(f, n, f".fill count {count} must be non-negative")
                val = _eval_expr(ops[1], self.labels, f, n, self.radix) & WORD_MASK if len(ops) > 1 else 0
                return [val] * count

            case '.align':
                if not ops_str.strip():
                    raise AsmError(f, n, ".align requires an argument")
                align = _eval_expr(ops_str.strip(), self.labels, f, n, self.radix)
                if align < 1:
                    raise AsmError(f, n, f".align argument {align} must be >= 1")
                return [0] * ((-addr) % align)

            case 'and':
                self._expect(ops, 3, mnem, f, n)
                return encode_r3(OP_AND, _reg(ops[0],f,n), _reg(ops[1],f,n), _reg(ops[2],f,n))
            case 'add' | 'addc':
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
                return encode_ri(OP_LUI, rd, _imm6(_eval_expr(ops[1], self.labels, f, n, self.radix), f, n))

            case 'addi':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "addi cannot target r0 (use bt for branches)")
                if rd == 7:
                    raise AsmError(f, n, "addi cannot target r7 (use bt for branches)")
                return encode_ri(OP_ADDI, rd, _imm6(_eval_expr(ops[1], self.labels, f, n, self.radix), f, n))

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
                self._expect(ops, 2, mnem, f, n)
                op = OP_LW if mnem == 'lw' else OP_SW
                rd = _reg(ops[0], f, n)
                val = _eval_expr(ops[1], self.labels, f, n, self.radix)
                return encode_ri(op, rd, _resolve_mem_operand(val, rd, self.bases, f, n))

            case 'li':
                self._expect(ops, 2, mnem, f, n)
                rd = _reg(ops[0], f, n)
                if rd == 0:
                    raise AsmError(f, n, "li cannot target r0")
                val = _eval_expr(ops[1], self.labels, f, n, self.radix)
                if val < -2048 or val > WORD_MASK:
                    raise AsmError(f, n, f"li value {val} out of 12-bit range")
                val &= WORD_MASK
                lower = val & IMM6_MASK
                upper = (val >> 6) & IMM6_MASK
                # addi sign-extends lower; if bit 5 is set it subtracts 64, so add 1 to upper to compensate
                if lower >= 32:
                    upper = (upper + 1) & IMM6_MASK
                return [encode_ri(OP_LUI, rd, upper), encode_ri(OP_ADDI, rd, lower)]

            case _:
                raise AsmError(f, n, f"unknown mnemonic '{mnem}'")

    def _branch_operand(self, operand, instr_addr, filename, lineno):
        """Resolve branch operand to a signed offset in -64..63."""
        if re.fullmatch(r'[A-Za-z_]\w*', operand):
            if operand not in self.labels:
                raise AsmError(filename, lineno, f"undefined label '{operand}'")
            offset = self.labels[operand] - instr_addr
        else:
            offset = _eval_expr(operand, self.labels, filename, lineno, self.radix)
        if offset < -64 or offset > 63:
            raise AsmError(filename, lineno,
                f"branch offset {offset:+d} out of range (-64..63)")
        return offset

    @staticmethod
    def _parse_string_literal(s, filename, lineno):
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
    parser = argparse.ArgumentParser(description='RRISC assembler')
    parser.add_argument('source', help='input .asm file')
    parser.add_argument('-o', '--output', help='output file (default: <source>.bin or .mem)')
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
        print(f"asm.py: {args.source}: not a text file", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"asm.py: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        asm = Assembler(args.source)
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
