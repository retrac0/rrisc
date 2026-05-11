#!/usr/bin/env python3
"""RRISC linker — Python port of ``RRISC.Link`` (Haskell)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import NamedTuple

from . import objfmt
from .isa import (
    OP_ADDI,
    OP_LUI,
    OP_SPEC,
    RB_JALR,
    WORD_MASK,
    IMM6_MASK,
    encode_r3,
    encode_ri,
)


@dataclass
class LinkOptions:
    lo_section_bases: list[tuple[str, int]] = field(default_factory=lambda: [("text", 0)])


default_link_options = LinkOptions()


@dataclass
class PlacedSymbol:
    name: str
    object_path: str
    section: str
    linkage: objfmt.Linkage
    addr: int


@dataclass
class PlacedSection:
    sec_name: str
    base: int
    size: int


@dataclass
class LinkResult:
    words: list[int]
    symbols: list[PlacedSymbol]
    sections: list[PlacedSection]
    inputs: list[str]


class LinkError(Exception):
    pass


def format_link_error(e: Exception) -> str:
    if isinstance(e, LinkError):
        return str(e)
    return str(e)


# --- Items ---


class ItemWord(NamedTuple):
    w: int


class ItemBrel(NamedTuple):
    src: str
    bk: objfmt.BranchKind
    sym: str
    addend: int


class ItemReloc(NamedTuple):
    src: str
    kind: objfmt.RelocKind
    ws: list[int]
    sym: str
    addend: int


class ItemSym(NamedTuple):
    src: str
    name: str
    linkage: objfmt.Linkage
    offset: int | None


class ItemLoc(NamedTuple):
    src: str
    lineno: int


Item = ItemWord | ItemBrel | ItemReloc | ItemSym | ItemLoc


def reloc_span(kind: objfmt.RelocKind) -> int:
    return objfmt.reloc_placeholder_words(kind)


def _records_to_items_fixed(src: str, records: list[objfmt.SecRecord]) -> list[Item]:
    """Flatten records to Items (Haskell ``recordsToItems``).

    Placeholder words appear in file before ``reloc``; ``acc`` uses append order
    (low-to-high address). Pop from the end (nearest reloc first). The collected
    word list matches Haskell's ``ItemReloc`` word order (see ``RRISC.Link``).
    """
    acc: list[Item] = []

    def pop_placeholders(
        k: int, stack: list[Item]
    ) -> tuple[list[int], list[Item]] | None:
        collected: list[int] = []
        rest = stack
        while k > 0:
            if not rest:
                return None
            it = rest[-1]
            rest = rest[:-1]
            if isinstance(it, ItemWord):
                collected.append(it.w)
                k -= 1
            else:
                return None
        return (collected, rest)

    i = 0
    rs = records
    while i < len(rs):
        r = rs[i]
        i += 1
        if isinstance(r, objfmt.RecWord):
            acc.append(ItemWord(r.w))
        elif isinstance(r, objfmt.RecZero):
            acc.extend([ItemWord(0)] * max(0, r.n))
        elif isinstance(r, objfmt.RecSym):
            acc.append(ItemSym(src, r.name, r.linkage, r.offset))
        elif isinstance(r, objfmt.RecLoc):
            acc.append(ItemLoc(src, r.lineno))
        elif isinstance(r, objfmt.RecBrel):
            acc.append(ItemBrel(src, r.branch_kind, r.symbol, r.addend))
        elif isinstance(r, objfmt.RecReloc):
            n = reloc_span(r.kind)
            popped = pop_placeholders(n, acc)
            if popped is None:
                raise LinkError(
                    f"{src}: 'reloc' record must follow N word records "
                    "(no sym/loc/brel between them)"
                )
            ws, acc = popped
            acc.append(ItemReloc(src, r.kind, ws, r.symbol, r.addend))
        else:
            raise LinkError(f"{src}: unknown record {r!r}")

    return acc


@dataclass
class SectionPiece:
    source: str
    name: str
    items: list[Item]


def collect_section_order(pieces: list[SectionPiece]) -> list[str]:
    acc: list[str] = []

    def go(ps: list[SectionPiece]) -> list[str]:
        out: list[str] = []
        for p in ps:
            if p.name not in out:
                out.append(p.name)
        return out

    return go(pieces)


def assign_bases(opts: LinkOptions, sec_order: list[str]) -> list[tuple[str, int]]:
    pinned = opts.lo_section_bases
    pinned_names = {x[0] for x in pinned}
    unpinned = [n for n in sec_order if n not in pinned_names]
    return list(pinned) + [(n, 0) for n in unpinned]


def section_base(bases: list[tuple[str, int]], nm: str) -> int:
    for k, v in bases:
        if k == nm:
            return v
    return 0


def item_size(relaxed: set[int], idx: int, it: Item) -> int:
    if isinstance(it, ItemWord):
        return 1
    if isinstance(it, ItemBrel):
        return 4 if idx in relaxed else 1
    if isinstance(it, ItemReloc):
        return reloc_span(it.kind)
    if isinstance(it, ItemSym) or isinstance(it, ItemLoc):
        return 0
    return 0


@dataclass
class Layout:
    offsets: list[int]
    total: int


def layout_section(relaxed: set[int], items: list[Item]) -> Layout:
    sizes = [item_size(relaxed, i, it) for i, it in enumerate(items)]
    offs = []
    cur = 0
    for s in sizes:
        offs.append(cur)
        cur += s
    return Layout(offsets=offs, total=cur)


@dataclass
class SymbolEnv:
    global_: dict[str, int] = field(default_factory=dict)
    local: dict[tuple[str, str], int] = field(default_factory=dict)


def collect_placed_symbols(
    bases: list[tuple[str, int]],
    final_layouts: list[tuple[str, Layout, list[Item]]],
) -> list[PlacedSymbol]:
    out: list[PlacedSymbol] = []
    for secnm, layout, items in final_layouts:
        base = section_base(bases, secnm)
        for idx, it in enumerate(items):
            if not isinstance(it, ItemSym):
                continue
            if it.linkage == objfmt.Linkage.EXTERN:
                continue
            obj_fp, name, lk, mo = it.src, it.name, it.linkage, it.offset
            if mo is not None:
                addr = base + mo
            else:
                addr = base + layout.offsets[idx]
            out.append(
                PlacedSymbol(
                    name=name,
                    object_path=obj_fp,
                    section=secnm,
                    linkage=lk,
                    addr=addr,
                )
            )
    return out


def build_symbol_env(
    bases: list[tuple[str, int]],
    sections: list[tuple[str, Layout, list[Item]]],
) -> SymbolEnv:
    env = SymbolEnv()

    def merge_item(secnm: str, layout: Layout, idx: int, it: Item) -> None:
        if not isinstance(it, ItemSym):
            return
        if it.linkage == objfmt.Linkage.EXTERN:
            return
        base = section_base(bases, secnm)
        if it.offset is not None:
            addr = base + it.offset
        else:
            addr = base + layout.offsets[idx]
        lk = it.linkage
        if lk == objfmt.Linkage.LOCAL:
            env.local[it.src, it.name] = addr
            return
        if lk in (objfmt.Linkage.GLOBAL, objfmt.Linkage.WEAK):
            prev = env.global_.get(it.name)
            if prev is not None and prev != addr:
                raise LinkError(
                    f"duplicate definition of '{it.name}' at 0o{oct(prev)} and 0o{oct(addr)}"
                )
            env.global_[it.name] = addr

    for secnm, layout, items in sections:
        for idx, it in enumerate(items):
            merge_item(secnm, layout, idx, it)

    return env


def resolve_sym(obj_fp: str, name: str, env: SymbolEnv) -> int:
    key = (obj_fp, name)
    if key in env.local:
        return env.local[key]
    if name in env.global_:
        return env.global_[name]
    raise LinkError(f"undefined reference to '{name}'")


def set_imm6(w: int, v: int) -> int:
    complement6 = WORD_MASK ^ IMM6_MASK
    return (w & complement6) | (v & IMM6_MASK)


def set_rd(w: int, rd: int) -> int:
    complement_rd = WORD_MASK ^ (7 << 6)
    return (w & complement_rd) | ((rd & 7) << 6)


def patch_placeholders(
    kind: objfmt.RelocKind,
    ws: list[int],
    val: int,
    branch_addr: int,
) -> list[int]:
    masked = val & WORD_MASK
    if kind == objfmt.RelocKind.IMM12:
        return [masked]
    hi6 = (masked >> 6) & IMM6_MASK
    lo6 = masked & IMM6_MASK
    if kind == objfmt.RelocKind.LI_IMM12:
        if len(ws) != 2:
            raise LinkError("li-imm12 reloc must cover exactly 2 words")
        return [set_imm6(ws[0], hi6), set_imm6(ws[1], lo6)]
    if kind == objfmt.RelocKind.JMP_TARGET12:
        if len(ws) != 3:
            raise LinkError("jmp-target12 reloc must cover exactly 3 words")
        return [set_imm6(ws[0], hi6), set_imm6(ws[1], lo6), ws[2]]
    if kind == objfmt.RelocKind.CALL_TARGET12:
        if len(ws) != 3:
            raise LinkError("call-target12 reloc must cover exactly 3 words")
        return [set_imm6(ws[0], hi6), set_imm6(ws[1], lo6), ws[2]]
    if kind == objfmt.RelocKind.IMM6_PC:
        if len(ws) != 1:
            raise LinkError("imm6-pc reloc must cover exactly 1 word")
        off = masked - branch_addr
        rd = 7 if off < 0 else 0
        if off < -64 or off > 63:
            raise LinkError(f"branch offset {off:+d} out of range")
        return [set_imm6(set_rd(ws[0], rd), off & IMM6_MASK)]
    raise LinkError(f"unknown reloc kind {kind}")


def relax_loop(
    merged: list[tuple[str, list[Item]]],
    bases: list[tuple[str, int]],
    relaxed: dict[str, set[int]],
    budget: int,
) -> dict[str, set[int]]:
    if budget <= 0:
        raise LinkError("branch relaxation failed to converge (budget exhausted)")

    layouts = []
    for nm, its in merged:
        ly = layout_section(relaxed.get(nm, set()), its)
        layouts.append((nm, ly, its))

    sym_env = build_symbol_env(bases, layouts)

    relaxed_new = {k: set(v) for k, v in relaxed.items()}
    changed = False

    for nm, layout, items in layouts:
        base = section_base(bases, nm)
        sec_rel = relaxed_new.setdefault(nm, set())
        for idx, it in enumerate(items):
            if not isinstance(it, ItemBrel):
                continue
            if idx in sec_rel:
                continue
            fp, bk, sym, addend = it.src, it.bk, it.sym, it.addend
            target = resolve_sym(fp, sym, sym_env)
            off_item = layout.offsets[idx]
            branch_addr = base + off_item
            offset = (target + addend) - branch_addr
            if offset < -64 or offset > 63:
                sec_rel.add(idx)
                changed = True

    if changed:
        return relax_loop(merged, bases, relaxed_new, budget - 1)
    return relaxed_new


def emit_item(
    base: int,
    sec_rel: set[int],
    sym_env: SymbolEnv,
    idx: int,
    it: Item,
    off: int,
) -> list[tuple[int, int]]:
    if isinstance(it, ItemWord):
        return [(base + off, it.w & WORD_MASK)]
    if isinstance(it, ItemSym) or isinstance(it, ItemLoc):
        return []
    if isinstance(it, ItemReloc):
        target = resolve_sym(it.src, it.sym, sym_env)
        val = target + it.addend
        branch_addr = base + off
        patched = patch_placeholders(
            it.kind, list(reversed(it.ws)), val, branch_addr
        )
        return [
            (base + off + i, w & WORD_MASK) for i, w in enumerate(patched)
        ]
    if isinstance(it, ItemBrel):
        target = resolve_sym(it.src, it.sym, sym_env)
        branch_addr = base + off
        offset = (target + it.addend) - branch_addr
        is_relaxed = idx in sec_rel
        if not is_relaxed:
            if offset < -64 or offset > 63:
                raise LinkError(
                    f"branch to '{it.sym}' offset {offset:+d} out of range after relaxation"
                )
            rd = 7 if offset < 0 else 0
            op = OP_ADDI if it.bk == objfmt.BranchKind.BT else OP_LUI
            return [(branch_addr, encode_ri(op, rd, offset & IMM6_MASK))]
        inv_op = OP_LUI if it.bk == objfmt.BranchKind.BT else OP_ADDI
        tgt = (target + it.addend) & WORD_MASK
        hi6 = (tgt >> 6) & IMM6_MASK
        lo6 = tgt & IMM6_MASK
        return [
            (branch_addr, encode_ri(inv_op, 0, 4)),
            (branch_addr + 1, encode_ri(OP_LUI, 4, hi6)),
            (branch_addr + 2, encode_ri(OP_ADDI, 4, lo6)),
            (branch_addr + 3, encode_r3(OP_SPEC, 0, 4, RB_JALR)),
        ]
    raise LinkError(f"emit_item: unknown {it!r}")


def emit_section(
    bases: list[tuple[str, int]],
    relaxed: dict[str, set[int]],
    sym_env: SymbolEnv,
    nm: str,
    layout: Layout,
    items: list[Item],
) -> list[tuple[int, int]]:
    base = section_base(bases, nm)
    sec_rel = relaxed.get(nm, set())
    out: list[tuple[int, int]] = []
    for idx, it in enumerate(items):
        off = layout.offsets[idx]
        out.extend(emit_item(base, sec_rel, sym_env, idx, it, off))
    return out


def link_object_files(
    opts: LinkOptions,
    inputs: list[tuple[str, objfmt.ObjectFile]],
) -> LinkResult:
    pieces: list[SectionPiece] = []
    for fp, obj in inputs:
        for sec in obj.sections:
            its = _records_to_items_fixed(fp, sec.records)
            pieces.append(SectionPiece(fp, sec.name, its))

    by_section: dict[str, list[SectionPiece]] = {}
    for p in pieces:
        by_section.setdefault(p.name, []).append(p)

    sec_order = collect_section_order(pieces)
    bases = assign_bases(opts, sec_order)

    merged = []
    for nm in sec_order:
        chunks = by_section.get(nm, [])
        concat_items: list[Item] = []
        for c in chunks:
            concat_items.extend(c.items)
        merged.append((nm, concat_items))

    budget = len(pieces) * 4 + 16
    final_relaxed = relax_loop(merged, bases, {}, budget)

    final_layouts = []
    for nm, items in merged:
        ly = layout_section(final_relaxed.get(nm, set()), items)
        final_layouts.append((nm, ly, items))

    sym_env = build_symbol_env(bases, final_layouts)

    emitted = []
    for nm, ly, items in final_layouts:
        emitted.extend(
            emit_section(bases, final_relaxed, sym_env, nm, ly, items)
        )

    symbols = collect_placed_symbols(bases, final_layouts)

    placed_sections = []
    for nm, ly, _ in final_layouts:
        placed_sections.append(
            PlacedSection(sec_name=nm, base=section_base(bases, nm), size=ly.total)
        )

    flat_pairs = emitted
    max_addr = max((a for a, _ in flat_pairs), default=-1)
    if max_addr < 0:
        img: list[int] = []
    else:
        img = [0] * (max_addr + 1)
        for a, w in flat_pairs:
            if a > WORD_MASK:
                raise LinkError(
                    f"section word at {oct(a)} exceeds 12-bit address space"
                )
            img[a] = w & WORD_MASK

    for s in placed_sections:
        if s.size > 0:
            last = s.base + s.size - 1
            if last > WORD_MASK:
                inp0 = inputs[0][0] if inputs else "<no inputs>"
                raise LinkError(
                    f"{inp0}: section '{s.sec_name}' word at {oct(last)} exceeds 12-bit address space"
                )

    return LinkResult(
        words=img,
        symbols=symbols,
        sections=placed_sections,
        inputs=[fp for fp, _ in inputs],
    )


def link_files(opts: LinkOptions, paths: list[str]) -> LinkResult:
    objs: list[tuple[str, objfmt.ObjectFile]] = []
    for p in paths:
        r = objfmt.read_object_file(p)
        if isinstance(r, objfmt.ObjParseError):
            raise LinkError(objfmt.format_obj_parse_error(r))
        objs.append((p, r))
    return link_object_files(opts, objs)


def render_map(lr: LinkResult) -> str:
    lines = ["RRISC link map", "", "Inputs:"]
    for inp in lr.inputs:
        lines.append(f"  {inp}")
    lines.extend(["", "Sections:"])
    for s in lr.sections:
        lines.append(
            f"  {s.sec_name:<8}  base=0o{oct(s.base)[2:]}  size=0o{oct(s.size)[2:]}"
        )
    syms = sorted(lr.symbols, key=lambda x: x.addr)
    lines.extend(["", "Symbols (sorted by address):"])
    for sym in syms:
        lk = sym.linkage.value
        lines.append(
            f"  {sym.name:<20}  {sym.object_path:<28}  0o{oct(sym.addr)[2:]}  {sym.section:<8}  {lk}"
        )
    return "\n".join(lines) + "\n"


def write_binary_words(path: str, words: list[int]) -> None:
    with open(path, "wb") as f:
        for w in words:
            w &= WORD_MASK
            f.write(bytes([w & 0xFF, (w >> 8) & 0x0F]))


def write_readmemb_words(path: str, words: list[int]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        for w in words:
            f.write(f"{w & WORD_MASK:012b}\n")
