#!/usr/bin/env python3
"""
Report RRISC textual .o section sizes (in 12-bit words).

Example:
  scripts/rrisc_obj_size.py build/rrisc-float-obj/rrisc_float_bundle.o
"""

from __future__ import annotations

import argparse
from pathlib import Path


def _parse_int(tok: str) -> int:
    tok = tok.strip()
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


def section_word_count(obj_path: Path, section: str) -> int:
    in_section: str | None = None
    words = 0
    for raw in obj_path.read_text().splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if line.startswith("section "):
            in_section = line.split(None, 1)[1].strip()
            continue
        if line == "endsec":
            in_section = None
            continue
        if in_section != section:
            continue
        toks = line.split(None, 1)
        kw = toks[0]
        if kw == "word":
            words += 1
        elif kw == "zero":
            words += _parse_int(toks[1])
    return words


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("obj", type=Path, help="RRISC textual .o (hsasm --emit-obj)")
    ap.add_argument(
        "--sections",
        default="text,data",
        help="Comma-separated sections to report (default: text,data)",
    )
    args = ap.parse_args()

    obj: Path = args.obj
    if not obj.is_file():
        raise SystemExit(f"not a file: {obj}")

    sections = [s.strip() for s in args.sections.split(",") if s.strip()]
    for s in sections:
        print(f"{s}\t{section_word_count(obj, s)}\t{obj}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

