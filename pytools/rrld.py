#!/usr/bin/env python3
"""``rrld`` — Python linker (``RRISC.Link`` port). CLI matches Haskell ``rrld``."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from . import link_core


def _parse_int_arg(s: str) -> int | None:
    s = s.strip()
    if re.fullmatch(r"-?[0-9]+", s):
        try:
            return int(s)
        except ValueError:
            return None
    if len(s) >= 3 and s[0] == "0" and s[1].lower() == "o":
        try:
            return int(s[2:], 8)
        except ValueError:
            return None
    if len(s) >= 3 and s[0] == "0" and s[1].lower() == "x":
        try:
            return int(s[2:], 16)
        except ValueError:
            return None
    if len(s) >= 3 and s[0] == "0" and s[1].lower() == "b":
        try:
            return int(s[2:], 2)
        except ValueError:
            return None
    return None


def main(argv: list[str] | None = None) -> None:
    argv = argv if argv is not None else sys.argv[1:]
    if argv in (["-V"], ["--version"]):
        print("rrld 1.0 (pytools)")
        raise SystemExit(0)

    ap = argparse.ArgumentParser(prog="rrld", description="RRISC linker (Python)")
    ap.add_argument("inputs", nargs="+", metavar="input.o")
    ap.add_argument("-o", "--output", dest="output")
    ap.add_argument("--format", choices=("bin", "readmemb"), default="bin")
    ap.add_argument("--map", dest="map_file")
    ap.add_argument("--code-base")
    ap.add_argument("--data-base")
    args = ap.parse_args(argv)

    bases: list[tuple[str, int]] = []
    if args.code_base is not None:
        cb = _parse_int_arg(args.code_base)
        if cb is None:
            print(f"rrld: bad --code-base {args.code_base!r}", file=sys.stderr)
            raise SystemExit(2)
        bases.append(("text", cb))
    if args.data_base is not None:
        db = _parse_int_arg(args.data_base)
        if db is None:
            print(f"rrld: bad --data-base {args.data_base!r}", file=sys.stderr)
            raise SystemExit(2)
        bases.append(("data", db))

    opts = (
        link_core.LinkOptions(lo_section_bases=bases)
        if bases
        else link_core.default_link_options
    )

    try:
        lr = link_core.link_files(opts, args.inputs)
    except link_core.LinkError as e:
        print(link_core.format_link_error(e), file=sys.stderr)
        raise SystemExit(1)

    out = args.output
    if not out:
        inp = Path(args.inputs[0])
        ext = ".mem" if args.format == "readmemb" else ".bin"
        out = str(inp.with_suffix(ext)) if inp.suffix else str(inp) + ext

    if args.format == "readmemb":
        link_core.write_readmemb_words(out, lr.words)
    else:
        link_core.write_binary_words(out, lr.words)

    if args.map_file:
        Path(args.map_file).write_text(link_core.render_map(lr), encoding="utf-8")


if __name__ == "__main__":
    main()
