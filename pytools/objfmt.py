#!/usr/bin/env python3
"""Textual RRISC relocatable object format — mirrors ``RRISC.Obj.Format`` (Haskell)."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import NamedTuple

# Must match tools/src/RRISC/Obj/Format.hs objVersion
OBJ_VERSION = 1
WORD_MASK = 0o7777
IMM6_MASK = 0o77


class Linkage(Enum):
    LOCAL = "local"
    GLOBAL = "global"
    EXTERN = "extern"
    WEAK = "weak"


class RelocKind(Enum):
    IMM12 = "imm12"
    LI_IMM12 = "li-imm12"
    JMP_TARGET12 = "jmp-target12"
    CALL_TARGET12 = "call-target12"
    IMM6_PC = "imm6-pc"


class BranchKind(Enum):
    BT = "bt"
    BF = "bf"


@dataclass
class SecRecord:
    """One record inside a section (discriminated union as subclasses)."""

    pass


@dataclass
class RecWord(SecRecord):
    w: int


@dataclass
class RecZero(SecRecord):
    n: int


@dataclass
class RecSym(SecRecord):
    name: str
    linkage: Linkage
    offset: int | None  # None = current offset


@dataclass
class RecLoc(SecRecord):
    path: str
    lineno: int


@dataclass
class RecReloc(SecRecord):
    kind: RelocKind
    symbol: str
    addend: int


@dataclass
class RecBrel(SecRecord):
    branch_kind: BranchKind
    symbol: str
    addend: int


@dataclass
class Section:
    name: str
    records: list[SecRecord] = field(default_factory=list)


@dataclass
class ObjectFile:
    version: int = OBJ_VERSION
    sources: list[str] = field(default_factory=list)
    sections: list[Section] = field(default_factory=list)


class ObjParseError(NamedTuple):
    path: str
    line: int
    msg: str


def format_obj_parse_error(e: ObjParseError) -> str:
    return f"{e.path}:{e.line}: {e.msg}"


def reloc_placeholder_words(kind: RelocKind) -> int:
    return {
        RelocKind.IMM12: 1,
        RelocKind.LI_IMM12: 2,
        RelocKind.JMP_TARGET12: 3,
        RelocKind.CALL_TARGET12: 3,
        RelocKind.IMM6_PC: 1,
    }[kind]


def section_symbols(sec: Section) -> list[tuple[str, Linkage, int]]:
    """``(name, linkage, offset)`` for each ``sym`` record (matches Haskell)."""

    # Walk with running offset (Haskell folds records in order)
    out: list[tuple[str, Linkage, int]] = []
    off = 0
    for r in sec.records:
        if isinstance(r, RecWord):
            off += 1
        elif isinstance(r, RecZero):
            off += max(0, r.n)
        elif isinstance(r, RecSym):
            addr = off if r.offset is None else r.offset
            out.append((r.name, r.linkage, addr))
        elif isinstance(r, RecLoc):
            continue
        elif isinstance(r, RecReloc):
            off += reloc_placeholder_words(r.kind)
        elif isinstance(r, RecBrel):
            off += 1
    return out


def section_words(sec: Section) -> list[int]:
    out: list[int] = []

    def walk(rs: list[SecRecord]) -> None:
        for r in rs:
            if isinstance(r, RecWord):
                out.append(r.w & WORD_MASK)
            elif isinstance(r, RecZero):
                out.extend([0] * max(0, r.n))
            # sym/loc/reloc/brel contribute no raw words in sectionWords (Haskell)

    walk(sec.records)
    return out


# --- render ---


def _tshow(n: int) -> str:
    return str(n)


def _oct_word(w: int) -> str:
    x = w & WORD_MASK
    s = oct(x)[2:]  # strip 0o
    if s == "":
        s = "0"
    pad = max(0, 4 - len(s))
    return "0o" + ("0" * pad) + s


def _quote_string(fp: str) -> str:
    esc = []
    for c in fp:
        if c == "\\":
            esc.append("\\\\")
        elif c == '"':
            esc.append('\\"')
        elif c == "\n":
            esc.append("\\n")
        elif c == "\t":
            esc.append("\\t")
        else:
            esc.append(c)
    return '"' + "".join(esc) + '"'


def _render_linkage(lk: Linkage) -> str:
    return lk.value


def _render_addend(n: int) -> str:
    if n == 0:
        return ""
    if n > 0:
        return " +" + str(n)
    return " " + str(n)


def render_object(obj: ObjectFile) -> str:
    lines: list[str] = ["rrisc-obj " + str(obj.version)]
    for src in obj.sources:
        lines.append("source " + _quote_string(src))
    for sec in obj.sections:
        lines.extend(_render_section(sec))
    return "\n".join(lines) + "\n"


def _render_section(sec: Section) -> list[str]:
    out = ["section " + sec.name]
    for r in sec.records:
        out.append("  " + _render_rec(r))
    out.append("endsec")
    return out


def _render_rec(r: SecRecord) -> str:
    if isinstance(r, RecWord):
        return "word " + _oct_word(r.w)
    if isinstance(r, RecZero):
        return "zero " + str(r.n)
    if isinstance(r, RecSym):
        base = f"sym {r.name} {_render_linkage(r.linkage)}"
        if r.offset is not None:
            return base + " " + str(r.offset)
        return base
    if isinstance(r, RecLoc):
        return f"loc {_quote_string(r.path)} {r.lineno}"
    if isinstance(r, RecReloc):
        return (
            "reloc "
            + r.kind.value
            + " "
            + r.symbol
            + _render_addend(r.addend)
        )
    if isinstance(r, RecBrel):
        return (
            "brel "
            + r.branch_kind.value
            + " "
            + r.symbol
            + _render_addend(r.addend)
        )
    raise TypeError(r)


def write_object_file(path: str, obj: ObjectFile) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(render_object(obj))


# --- parse ---


def _strip_comment(line: str) -> str:
    return line.split(";", 1)[0]


def _parse_int_tok(tok: str) -> int | None:
    t = tok.strip()
    if not t:
        return None
    sign = 1
    if t.startswith("-"):
        sign = -1
        t = t[1:]
    elif t.startswith("+"):
        t = t[1:]
    if t.startswith(("0o", "0O")):
        return sign * int(t[2:], 8)
    if t.startswith(("0x", "0X")):
        return sign * int(t[2:], 16)
    if t.startswith(("0b", "0B")):
        return sign * int(t[2:], 2)
    # Haskell reads decimal; leading 0 octal in readsT uses 0o prefix only in Body
    if t.startswith("0") and len(t) > 1 and t[1].isdigit():
        # ambiguous — Format.hs readBody: ('0':'o':digits) for octal
        pass
    try:
        return sign * int(t, 10)
    except ValueError:
        return None


def _parse_quoted(s: str) -> tuple[str, str] | None:
    s = s.strip()
    if not s.startswith('"'):
        return None
    i = 1
    acc: list[str] = []
    while i < len(s):
        c = s[i]
        if c == '"':
            return "".join(acc), s[i + 1 :]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            if n == "n":
                acc.append("\n")
            elif n == "t":
                acc.append("\t")
            else:
                acc.append(n)
            i += 2
            continue
        acc.append(c)
        i += 1
    return None


def parse_object(path: str, body: str) -> ObjectFile | ObjParseError:
    lines = list(enumerate(body.splitlines(), start=1))
    rest = [(ln, raw) for ln, raw in lines if _strip_comment(raw).strip()]
    while rest and not _strip_comment(rest[0][1]).strip():
        rest.pop(0)

    if not rest:
        return ObjParseError(path, 1, "empty object file")

    hl, header = rest[0]
    rest = rest[1:]
    hdr_w = _strip_comment(header).split()
    if len(hdr_w) != 2 or hdr_w[0] != "rrisc-obj":
        return ObjParseError(
            path,
            hl,
            "expected 'rrisc-obj <version>' header, got: " + _strip_comment(header).strip(),
        )
    try:
        ver = int(hdr_w[1])
    except ValueError:
        return ObjParseError(path, hl, "malformed version in 'rrisc-obj' header: " + hdr_w[1])
    if ver != OBJ_VERSION:
        return ObjParseError(
            path,
            hl,
            f"unsupported object version {ver} (this build expects {OBJ_VERSION})",
        )

    sources: list[str] = []
    sections: list[Section] = []
    cur_sec: tuple[int, str, list[SecRecord]] | None = None

    for ln, raw in rest:
        line = _strip_comment(raw).strip()
        if not line:
            continue
        parts = line.split(None, 1)
        kw = parts[0]

        if kw == "source":
            if cur_sec is not None:
                return ObjParseError(path, ln, "'source' not allowed inside section")
            tail = line[len("source") :].lstrip()
            q = _parse_quoted(tail)
            if q is None or q[1].strip():
                return ObjParseError(path, ln, 'expected a quoted "path"')
            sources.insert(0, q[0])  # Haskell finalize reverses sources
            continue

        if kw == "section":
            if cur_sec is not None:
                return ObjParseError(
                    path,
                    ln,
                    f"nested 'section' (previous opened at line {cur_sec[0]})",
                )
            nm = parts[1] if len(parts) > 1 else ""
            cur_sec = (ln, nm, [])

        elif line == "endsec":
            if cur_sec is None:
                return ObjParseError(path, ln, "'endsec' without matching 'section'")
            _, nm, recs = cur_sec
            sections.append(Section(name=nm, records=recs))
            cur_sec = None
        else:
            if cur_sec is None:
                return ObjParseError(
                    path,
                    ln,
                    "unexpected token outside section: " + line.split(None, 1)[0],
                )
            pr = _parse_record(path, ln, line)
            if isinstance(pr, ObjParseError):
                return pr
            cur_sec[2].append(pr)

    if cur_sec is not None:
        return ObjParseError(path, cur_sec[0], "unterminated section (missing 'endsec')")

    return ObjectFile(
        version=ver,
        sources=list(reversed(sources)),
        sections=list(reversed(sections)),
    )


def _parse_record(path: str, ln: int, line: str) -> SecRecord | ObjParseError:
    parts = line.split()
    if not parts:
        return ObjParseError(path, ln, "empty record")
    kw = parts[0]
    if kw == "word":
        tail = line[len("word") :].strip()
        toks = tail.split()
        if len(toks) != 1:
            return ObjParseError(path, ln, "'word' takes one value (use one record per word)")
        v = _parse_int_tok(toks[0])
        if v is None:
            return ObjParseError(path, ln, f"malformed integer literal '{toks[0]}'")
        return RecWord(v & WORD_MASK)
    if kw == "zero":
        tail = line[len("zero") :].strip()
        toks = tail.split()
        if len(toks) != 1:
            return ObjParseError(path, ln, "'zero' takes one count")
        n = _parse_int_tok(toks[0])
        if n is None or n < 0:
            return ObjParseError(path, ln, "'zero' count must be non-negative")
        return RecZero(n)
    if kw == "sym":
        tail = line[len("sym") :].strip()
        toks = tail.split()
        if len(toks) == 2:
            lk = _parse_linkage(path, ln, toks[1])
            if isinstance(lk, ObjParseError):
                return lk
            return RecSym(toks[0], lk, None)
        if len(toks) == 3:
            lk = _parse_linkage(path, ln, toks[1])
            if isinstance(lk, ObjParseError):
                return lk
            off = _parse_int_tok(toks[2])
            if off is None:
                return ObjParseError(path, ln, f"malformed integer literal '{toks[2]}'")
            return RecSym(toks[0], lk, off)
        return ObjParseError(path, ln, "expected 'sym <name> <linkage> [<offset>]'")
    if kw == "loc":
        tail = line[len("loc") :].strip()
        q = _parse_quoted(tail)
        if q is None:
            return ObjParseError(path, ln, 'expected \'loc "<path>" <line>\'')
        rest_toks = q[1].split()
        if len(rest_toks) != 1:
            return ObjParseError(path, ln, 'expected \'loc "<path>" <line>\'')
        li = _parse_int_tok(rest_toks[0])
        if li is None:
            return ObjParseError(path, ln, "malformed line number")
        return RecLoc(q[0], li)
    if kw == "reloc":
        tail = line[len("reloc") :].strip()
        toks = tail.split()
        if len(toks) < 2:
            return ObjParseError(path, ln, "expected 'reloc <kind> <symbol> [<addend>]'")
        rk = _parse_reloc_kind(path, ln, toks[0])
        if isinstance(rk, ObjParseError):
            return rk
        sym = toks[1]
        add = _parse_addend_tail(path, ln, toks[2:])
        if isinstance(add, ObjParseError):
            return add
        return RecReloc(rk, sym, add)
    if kw == "brel":
        tail = line[len("brel") :].strip()
        toks = tail.split()
        if len(toks) < 2:
            return ObjParseError(path, ln, "expected 'brel <bt|bf> <symbol> [<addend>]'")
        bk = _parse_branch_kind(path, ln, toks[0])
        if isinstance(bk, ObjParseError):
            return bk
        sym = toks[1]
        add = _parse_addend_tail(path, ln, toks[2:])
        if isinstance(add, ObjParseError):
            return add
        return RecBrel(bk, sym, add)
    return ObjParseError(path, ln, f"unknown record kind '{kw}'")


def _parse_linkage(path: str, ln: int, t: str) -> Linkage | ObjParseError:
    m = {
        "local": Linkage.LOCAL,
        "global": Linkage.GLOBAL,
        "extern": Linkage.EXTERN,
        "weak": Linkage.WEAK,
    }
    if t not in m:
        return ObjParseError(path, ln, f"unknown linkage class '{t}'")
    return m[t]


def _parse_reloc_kind(path: str, ln: int, t: str) -> RelocKind | ObjParseError:
    for rk in RelocKind:
        if rk.value == t:
            return rk
    return ObjParseError(path, ln, f"unknown reloc kind '{t}'")


def _parse_branch_kind(path: str, ln: int, t: str) -> BranchKind | ObjParseError:
    for bk in BranchKind:
        if bk.value == t:
            return bk
    return ObjParseError(path, ln, f"unknown branch kind '{t}'")


def _parse_addend_tail(path: str, ln: int, toks: list[str]) -> int | ObjParseError:
    if not toks:
        return 0
    if len(toks) > 1:
        return ObjParseError(path, ln, "trailing tokens after addend")
    v = toks[0]
    if v.startswith("+"):
        v = v[1:]
    iv = _parse_int_tok(v)
    if iv is None:
        return ObjParseError(path, ln, f"malformed integer literal '{toks[0]}'")
    return iv


def read_object_file(path: str) -> ObjectFile | ObjParseError:
    try:
        with open(path, encoding="utf-8") as f:
            txt = f.read()
    except OSError as e:
        return ObjParseError(path, 0, str(e))
    return parse_object(path, txt)


def round_trip(obj: ObjectFile) -> ObjectFile:
    """Parse after render — for tests."""
    text = render_object(obj)
    r = parse_object("<roundtrip>", text)
    if isinstance(r, ObjParseError):
        raise RuntimeError(format_obj_parse_error(r))
    return r
