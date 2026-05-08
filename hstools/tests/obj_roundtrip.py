#!/usr/bin/env python3
"""
Object-file round-trip check (step 1 of the toolchain refactor).

For every `.s` under tests/ and examples/, produce both a `.bin` and a `.o`
via hsasm, parse the `.o` back, reconstruct the flat word stream, and verify
it matches the `.bin`.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
HSASM = (
    REPO
    / "hstools"
    / "dist-newstyle"
    / "build"
    / "x86_64-linux"
    / "ghc-9.6.7"
    / "hstools-0.1.0.0"
    / "x"
    / "hsasm"
    / "build"
    / "hsasm"
    / "hsasm"
)


def parse_int(tok: str) -> int:
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


def parse_obj_words(obj_path: Path) -> list[int]:
    """Walk the textual .o and return the flat word stream of section 'text'."""
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
            words.append(parse_int(toks[1].strip()) & 0o7777)
        elif kw == "zero":
            n = parse_int(toks[1].strip())
            words.extend([0] * n)
        # sym / loc / reloc / brel don't move the offset for round-trip purposes
    return text_only


def read_bin(path: Path) -> list[int]:
    blob = path.read_bytes()
    if len(blob) % 2:
        raise ValueError(f"{path}: odd byte count {len(blob)}")
    out = []
    for i in range(0, len(blob), 2):
        lo, hi = blob[i], blob[i + 1]
        out.append(((hi & 0x0F) << 8) | (lo & 0xFF))
    # Trim trailing zeros to mirror writeBinary truncation? No — writeBinary
    # writes exactly maxAddr+1 words, and our obj also produces zero-padded
    # gaps to the last instruction.  No trimming.
    return out


def trim_trailing_zeros(ws: list[int]) -> list[int]:
    end = len(ws)
    while end > 0 and ws[end - 1] == 0:
        end -= 1
    return ws[:end]


def roundtrip(src: Path, tmp: Path, include_dirs: list[Path]) -> tuple[bool, str]:
    bin_path = tmp / (src.stem + ".bin")
    obj_path = tmp / (src.stem + ".o")
    cmd = [
        str(HSASM),
        str(src),
        "-o",
        str(bin_path),
        "--emit-obj",
        "--obj-out",
        str(obj_path),
    ]
    for d in include_dirs:
        cmd += ["-I", str(d)]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        return False, f"hsasm failed: {res.stderr.strip()}"
    bin_words = trim_trailing_zeros(read_bin(bin_path))
    obj_words = trim_trailing_zeros(parse_obj_words(obj_path))
    if bin_words != obj_words:
        n = max(len(bin_words), len(obj_words))
        diffs = []
        for i in range(n):
            b = bin_words[i] if i < len(bin_words) else None
            o = obj_words[i] if i < len(obj_words) else None
            if b != o:
                diffs.append(f"  addr {i:04o}: bin={b} obj={o}")
                if len(diffs) >= 10:
                    break
        return False, "word stream mismatch:\n" + "\n".join(diffs)
    return True, ""


def main() -> int:
    tmp = Path("/tmp/rrisc-obj-roundtrip")
    tmp.mkdir(exist_ok=True)
    sources: list[tuple[Path, list[Path]]] = []

    lib = REPO / "lib"
    for s in sorted((REPO / "examples").rglob("*.s")):
        sources.append((s, [lib]))
    for s in sorted((REPO / "tests").rglob("*.s")):
        # tests/ has both passing and failing-on-purpose inputs; skip the
        # "err-" inputs because they are meant to fail assembly.
        if s.name.startswith("err-"):
            continue
        sources.append((s, [lib]))

    ok = 0
    fail: list[str] = []
    for src, incs in sources:
        passed, msg = roundtrip(src, tmp, incs)
        rel = src.relative_to(REPO)
        if passed:
            ok += 1
        else:
            fail.append(f"{rel}\n{msg}")

    if fail:
        print(f"FAILED {len(fail)} of {ok + len(fail)}")
        for f in fail:
            print("---")
            print(f)
        return 1
    print(f"OK {ok}/{ok}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
