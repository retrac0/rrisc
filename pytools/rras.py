#!/usr/bin/env python3
"""``rras`` — Assembler CLI aligned with Haskell ``rras``.

Relocatable ``.o`` output (default) uses the Python assembler (``pytools.asm`` +
``asm_obj_emit``). Flat ``--format bin`` / ``readmemb`` uses the same tokenizer
and encoder for ``.bin`` / ``.mem`` images.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def _has_format_flag(argv: list[str]) -> bool:
    for a in argv:
        if a == "--format" or a.startswith("--format="):
            return True
    return False


def _flat_main(argv_tail: list[str]) -> None:
    from .asm import AsmError, Assembler, format_listing, write_binary, write_readmemb

    parser = argparse.ArgumentParser(description="RRISC assembler (Python flat mode)")
    parser.add_argument("source", help="input .asm file")
    parser.add_argument("-o", "--output", help="output file")
    parser.add_argument(
        "-I",
        dest="include_dirs",
        metavar="DIR",
        action="append",
        default=[],
        help="include directory (repeatable)",
    )
    parser.add_argument(
        "--format",
        choices=["bin", "readmemb"],
        default="bin",
        help="flat output format",
    )
    parser.add_argument("--list", action="store_true", help="listing to stdout")
    ns, unknown = parser.parse_known_args(argv_tail)
    if unknown:
        print(
            f"rras: unknown arguments in flat mode: {' '.join(unknown)}",
            file=sys.stderr,
        )
        raise SystemExit(2)

    default_ext = ".mem" if ns.format == "readmemb" else ".bin"
    out = ns.output or (re.sub(r"(\.\w+)?$", default_ext, ns.source, count=1))

    try:
        with open(ns.source, encoding="utf-8") as f:
            source = f.read()
    except UnicodeDecodeError:
        print(f"rras: {ns.source}: not a text file", file=sys.stderr)
        raise SystemExit(1)
    except OSError as e:
        print(f"rras: {e}", file=sys.stderr)
        raise SystemExit(1)

    try:
        asm = Assembler(ns.source, include_dirs=ns.include_dirs)
        words = asm.assemble(source)
        if ns.format == "readmemb":
            write_readmemb(words, out)
        else:
            write_binary(words, out)
        if ns.list:
            print(format_listing(asm._flat_lines, asm.listing_entries))
    except AsmError as e:
        print(e, file=sys.stderr)
        raise SystemExit(1)


def _parse_cli_defines(defines: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for d in defines:
        if "=" not in d:
            print("rras: -D requires NAME=value", file=sys.stderr)
            raise SystemExit(2)
        k, _, v = d.partition("=")
        if not k:
            print("rras: -D requires NAME=value", file=sys.stderr)
            raise SystemExit(2)
        out[k] = v
    return out


def _object_main(argv_tail: list[str]) -> None:
    from .asm import AsmError, Assembler
    from .objfmt import write_object_file

    parser = argparse.ArgumentParser(description="RRISC assembler (relocatable object output)")
    parser.add_argument("source", help="input .s / .asm file")
    parser.add_argument("-o", "--output", help="output .o file")
    parser.add_argument(
        "-I",
        dest="include_dirs",
        metavar="DIR",
        action="append",
        default=[],
        help="include directory (repeatable)",
    )
    parser.add_argument(
        "-D",
        dest="defines",
        metavar="NAME=value",
        action="append",
        default=[],
        help="assembler define (repeatable)",
    )
    try:
        ns = parser.parse_args(argv_tail)
    except SystemExit:
        raise

    src_path = Path(ns.source)
    if ns.output:
        out_path = ns.output
    else:
        out_path = (
            str(src_path.with_suffix(".o"))
            if src_path.suffix
            else str(src_path) + ".o"
        )

    try:
        with open(ns.source, encoding="utf-8") as f:
            source = f.read()
    except UnicodeDecodeError:
        print(f"rras: {ns.source}: not a text file", file=sys.stderr)
        raise SystemExit(1)
    except OSError as e:
        print(f"rras: {e}", file=sys.stderr)
        raise SystemExit(1)

    cli = _parse_cli_defines(ns.defines)
    try:
        asm = Assembler(ns.source, include_dirs=ns.include_dirs)
        obj = asm.assemble_object(source, cli_defines=cli)
        write_object_file(out_path, obj)
    except AsmError as e:
        print(e, file=sys.stderr)
        raise SystemExit(1)


def _dump_syms_main(path: str) -> None:
    from .objfmt import Linkage, read_object_file, section_symbols

    e = read_object_file(path)
    if isinstance(e, str):
        print(e, file=sys.stderr)
        raise SystemExit(1)
    obj = e

    def kind_letter(sec_name: str, lk) -> str:
        if lk == Linkage.EXTERN:
            return "U"
        base = {"text": "t", "rodata": "r", "data": "d", "bss": "b"}.get(
            sec_name, "?"
        )
        if lk == Linkage.LOCAL:
            return base
        return base.upper()

    rows = []
    for sec in obj.sections:
        for name, lk, off in section_symbols(sec):
            rows.append((sec.name, name, lk, off))
    rows.sort(key=lambda x: x[3])
    for sec_name, name, lk, off in rows:
        print(f"{off:04o} {kind_letter(sec_name, lk)} {name}")


def main(argv: list[str] | None = None) -> None:
    argv = argv if argv is not None else sys.argv[1:]
    if argv in (["-V"], ["--version"]):
        print("rras 1.0 (pytools)")
        raise SystemExit(0)

    if len(argv) >= 1 and argv[0] == "--dump-syms":
        if len(argv) != 2:
            print("Usage: rras --dump-syms file.o", file=sys.stderr)
            raise SystemExit(2)
        _dump_syms_main(argv[1])
        return

    if "--list" in argv and not _has_format_flag(argv):
        print(
            "rras: --list requires --format bin|readmemb",
            file=sys.stderr,
        )
        raise SystemExit(1)

    if _has_format_flag(argv):
        _flat_main(argv)
        return

    _object_main(argv)


if __name__ == "__main__":
    main()
