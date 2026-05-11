#!/usr/bin/env python3
"""Emit relocatable ``ObjectFile`` — Python port of ``RRISC.Obj.Emit``."""

from __future__ import annotations

import os
import re
from dataclasses import replace
from typing import Callable

from . import objfmt
from .isa import OP_ADDI, OP_LUI, WORD_MASK, encode_ri


def split_ops(ops_str: str) -> list[str]:
    if not ops_str or not ops_str.strip():
        return []
    return [x.strip() for x in ops_str.split(",")]


def is_simple_label(s: str) -> bool:
    s = s.strip()
    return bool(s) and bool(re.fullmatch(r"[A-Za-z_]\w*", s))


def parse_reg(fp: str, ln: int, tok: str) -> int:
    from .asm import _reg

    return _reg(tok.strip(), fp, ln)


def labels_from_stmts(stmts: list) -> dict[str, int]:
    m: dict[str, int] = {}
    for s in stmts:
        for lab in s.labels:
            m[lab] = s.addr
    return m


def linkage_directive_syms(ops_str: str) -> list[str]:
    return [x.strip() for x in ops_str.split(",") if x.strip()]


def linkage_map_from_stmts(stmts: list) -> dict[str, objfmt.Linkage]:
    m: dict[str, objfmt.Linkage] = {}
    for s in stmts:
        mn = s.mnemonic.lower()
        if mn not in (".global", ".globl", ".local"):
            continue
        for name in linkage_directive_syms(s.operands_str):
            if mn == ".local":
                m[name] = objfmt.Linkage.LOCAL
            else:
                m[name] = objfmt.Linkage.GLOBAL
    return m


def normalize_section(stmts: list):
    """Per-section address normalization (``normalizeSection`` / Haskell)."""
    if not stmts:
        return []
    b = min(s.addr for s in stmts)
    return [replace(s, addr=s.addr - b) for s in stmts]


EncodeFn = Callable[..., list[int]]


def _encode_dot_word(
    ops: list[str],
    fp: str,
    ln: int,
    labels: dict,
    encode_fallback: EncodeFn,
    template_stmt,
) -> tuple[list[objfmt.SecRecord], int]:
    from .asm import Statement

    if any(is_simple_label(x) for x in ops):
        recs: list[objfmt.SecRecord] = []
        for raw in ops:
            v = raw.strip()
            if is_simple_label(v):
                recs.append(objfmt.RecWord(0))
                recs.append(objfmt.RecReloc(objfmt.RelocKind.IMM12, v, 0))
            else:
                syn = replace(
                    template_stmt,
                    labels=[],
                    mnemonic=".word",
                    operands_str=v,
                )
                ws = encode_fallback(syn, labels)
                for ww in ws:
                    recs.append(objfmt.RecWord(ww & WORD_MASK))
        return recs, len(ops)
    ws = encode_fallback(template_stmt, labels)
    return [objfmt.RecWord(w & WORD_MASK) for w in ws], len(ws)


def emit_stmt_records(
    st,
    labels: dict,
    linkage: dict[str, objfmt.Linkage],
    encode_fallback: EncodeFn,
) -> tuple[list[objfmt.SecRecord], int]:
    """``emitStmt`` from ``Emit.hs`` (+ fallback)."""
    from .asm import AsmError, Statement

    mnem = st.mnemonic.lower()
    ops = split_ops(st.operands_str)
    fp, ln = st.filename, st.lineno

    if mnem in (".global", ".globl", ".local", ".section"):
        return [], 0

    if mnem == "bt" and len(ops) == 1 and is_simple_label(ops[0]):
        return (
            [objfmt.RecBrel(objfmt.BranchKind.BT, ops[0].strip(), 0)],
            1,
        )
    if mnem == "bf" and len(ops) == 1 and is_simple_label(ops[0]):
        return (
            [objfmt.RecBrel(objfmt.BranchKind.BF, ops[0].strip(), 0)],
            1,
        )

    if mnem == "li" and len(ops) == 2 and is_simple_label(ops[1]):
        try:
            rd = parse_reg(fp, ln, ops[0])
        except Exception:
            pass
        else:
            sym = ops[1].strip()
            return (
                [
                    objfmt.RecWord(encode_ri(OP_LUI, rd, 0)),
                    objfmt.RecWord(encode_ri(OP_ADDI, rd, 0)),
                    objfmt.RecReloc(objfmt.RelocKind.LI_IMM12, sym, 0),
                ],
                2,
            )

    if mnem == ".word":
        return _encode_dot_word(ops, fp, ln, labels, encode_fallback, st)

    ws = encode_fallback(st, labels)
    return [objfmt.RecWord(w & WORD_MASK) for w in ws], len(ws)


def build_records(
    stmts: list,
    labels: dict,
    linkage: dict[str, objfmt.Linkage],
    encode_fallback: EncodeFn,
) -> list[objfmt.SecRecord]:
    """``buildRecords`` from ``Emit.hs`` (forward record order)."""
    acc: list[objfmt.SecRecord] = []
    cursor = 0
    cur_loc: tuple[str, int] | None = None

    for st in stmts:
        target = st.addr
        gap = target - cursor
        if gap > 0:
            acc.append(objfmt.RecZero(gap))
        for lab in st.labels:
            acc.append(
                objfmt.RecSym(lab, linkage.get(lab, objfmt.Linkage.LOCAL), None)
            )
        loc = (st.filename, st.lineno)
        if st.mnemonic and str(st.mnemonic).strip():
            if cur_loc != loc:
                acc.append(objfmt.RecLoc(loc[0], loc[1]))
                cur_loc = loc

        instr_recs, advance = emit_stmt_records(
            st, labels, linkage, encode_fallback
        )
        acc.extend(instr_recs)
        cursor = target + advance

    return acc


def encode_to_object(stmts: list, flat_lines: list, assembler) -> objfmt.ObjectFile:
    """Port of ``encodeToObject``."""

    def encode_fallback(st, labels_map):
        assembler.labels = labels_map
        w = assembler._encode(st)
        if isinstance(w, list):
            return w
        return [w]

    by_sec: dict[str, list] = {}
    for st in stmts:
        sec = getattr(st, "section", "text")
        by_sec.setdefault(sec, []).append(st)

    sec_order: list[str] = list(
        dict.fromkeys(getattr(s, "section", "text") for s in stmts)
    )

    lk_all = linkage_map_from_stmts(stmts)
    sections_out: list[objfmt.Section] = []
    for nm in sec_order:
        raw = by_sec[nm]
        norm = normalize_section(raw)
        labs = labels_from_stmts(norm)
        rs = build_records(norm, labs, lk_all, encode_fallback)
        sections_out.append(objfmt.Section(name=nm, records=rs))

    sources: list[str] = []
    for rl in flat_lines:
        p = rl.filename
        if p and p not in sources:
            sources.append(p)

    return objfmt.ObjectFile(
        version=objfmt.OBJ_VERSION,
        sources=sources,
        sections=sections_out,
    )
