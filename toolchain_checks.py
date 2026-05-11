#!/usr/bin/env python3
"""Object round-trip and rld equivalence checks (shared by run_tests.py and tools/tests/*.py)."""

from __future__ import annotations

import filecmp
import subprocess
from pathlib import Path
from typing import Sequence


def collect_toolchain_asm_sources(root: Path) -> list[tuple[Path, list[Path]]]:
    """Assembly inputs for obj round-trip / rld equivalence.

    Only includes ``tools/tests/toolchain/*.s``: programs with ``.org`` emit a sparse flat
    ``.bin`` (zeros before the org) while ``rld`` packs the ``text`` section from
    base 0, so byte-identical single-object link checks do not apply repo-wide.
    """
    lib = root / "lib"
    tc = root / "tools" / "tests" / "toolchain"
    if not tc.is_dir():
        return []
    return [(s, [lib]) for s in sorted(tc.glob("*.s")) if s.is_file()]


def _parse_int(tok: str) -> int:
    sign = 1
    if tok.startswith("+"):
        tok = tok[1:]
    elif tok.startswith("-"):
        sign = -1
        tok = tok[1:]
    if tok.startswith(("0o", "0O")):
        return sign * int(tok[2:], 8)
    if tok.startswith(("0x", "0X")):
        return sign * int(tok[2:], 16)
    if tok.startswith(("0b", "0B")):
        return sign * int(tok[2:], 2)
    return sign * int(tok, 10)


def _parse_obj_text_section_words(obj_path: Path) -> list[int]:
    """Walk a textual .o and return words for section `text` (matches obj_roundtrip.py)."""
    in_section: str | None = None
    words: list[int] = []
    text_only: list[int] = []
    for raw in obj_path.read_text().splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if line.startswith("section "):
            in_section = line.split(None, 1)[1].strip()
            words = []
            continue
        if line == "endsec":
            if in_section == "text":
                text_only = words
            in_section = None
            continue
        if in_section is None:
            continue
        toks = line.split(None, 1)
        kw = toks[0]
        if kw == "word":
            words.append(_parse_int(toks[1].strip()) & 0o7777)
        elif kw == "zero":
            n = _parse_int(toks[1].strip())
            words.extend([0] * n)
    return text_only


def _read_bin(path: Path) -> list[int]:
    blob = path.read_bytes()
    if len(blob) % 2:
        raise ValueError(f"{path}: odd byte count {len(blob)}")
    out: list[int] = []
    for i in range(0, len(blob), 2):
        lo, hi = blob[i], blob[i + 1]
        out.append(((hi & 0x0F) << 8) | (lo & 0xFF))
    return out


def _trim_trailing_zeros(ws: list[int]) -> list[int]:
    end = len(ws)
    while end > 0 and ws[end - 1] == 0:
        end -= 1
    return ws[:end]


def _ras_inc_args(include_dirs: Sequence[Path]) -> list[str]:
    out: list[str] = []
    for d in include_dirs:
        out.extend(["-I", str(d)])
    return out


def verify_obj_roundtrip(
    ras: Path,
    src: Path,
    tmp: Path,
    include_dirs: Sequence[Path],
) -> tuple[bool, str]:
    bin_path = tmp / (src.stem + ".bin")
    obj_path = tmp / (src.stem + ".o")
    inc = _ras_inc_args(include_dirs)
    r1 = subprocess.run(
        [str(ras), str(src), "-o", str(obj_path), *inc],
        capture_output=True,
        text=True,
    )
    if r1.returncode != 0:
        return False, f"ras (.o) failed: {(r1.stderr or r1.stdout or '').strip()}"
    r2 = subprocess.run(
        [str(ras), str(src), "--format", "bin", "-o", str(bin_path), *inc],
        capture_output=True,
        text=True,
    )
    if r2.returncode != 0:
        return False, f"ras (flat .bin) failed: {(r2.stderr or r2.stdout or '').strip()}"
    bin_words = _trim_trailing_zeros(_read_bin(bin_path))
    obj_words = _trim_trailing_zeros(_parse_obj_text_section_words(obj_path))
    if bin_words != obj_words:
        n = max(len(bin_words), len(obj_words))
        diffs: list[str] = []
        for i in range(n):
            b = bin_words[i] if i < len(bin_words) else None
            o = obj_words[i] if i < len(obj_words) else None
            if b != o:
                diffs.append(f"  addr {i:04o}: bin={b} obj={o}")
                if len(diffs) >= 10:
                    break
        return False, "word stream mismatch:\n" + "\n".join(diffs)
    return True, ""


def verify_rld_equivalence(
    ras: Path,
    rld: Path,
    src: Path,
    tmp: Path,
    include_dirs: Sequence[Path],
) -> tuple[bool, str]:
    bin_path = tmp / (src.stem + ".bin")
    obj_path = tmp / (src.stem + ".o")
    linked_path = tmp / (src.stem + ".linked.bin")
    inc = _ras_inc_args(include_dirs)
    r1 = subprocess.run(
        [str(ras), str(src), "-o", str(obj_path), *inc],
        capture_output=True,
        text=True,
    )
    if r1.returncode != 0:
        return False, f"ras (.o) failed: {(r1.stderr or r1.stdout or '').strip()}"
    r2 = subprocess.run(
        [str(ras), str(src), "--format", "bin", "-o", str(bin_path), *inc],
        capture_output=True,
        text=True,
    )
    if r2.returncode != 0:
        return False, f"ras (flat .bin) failed: {(r2.stderr or r2.stdout or '').strip()}"
    res = subprocess.run(
        [str(rld), str(obj_path), "-o", str(linked_path)],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        return False, f"rld failed: {(res.stderr or res.stdout or '').strip()}"
    if not filecmp.cmp(bin_path, linked_path, shallow=False):
        a = bin_path.read_bytes()
        b = linked_path.read_bytes()
        diffs: list[str] = []
        n = max(len(a), len(b))
        for i in range(n):
            ax = a[i] if i < len(a) else None
            bx = b[i] if i < len(b) else None
            if ax != bx:
                diffs.append(f"  byte {i}: ras-flat={ax} rld={bx}")
                if len(diffs) >= 8:
                    break
        return False, "binary mismatch:\n" + "\n".join(diffs)
    return True, ""
