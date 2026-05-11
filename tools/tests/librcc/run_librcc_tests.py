#!/usr/bin/env python3
"""
Direct regression tests for lib/librcc.s (integer runtime used by rcc).

Each case builds crt0.o + librcc.o + a tiny user.o (main loads r3/r2, jalr to one
helper, halt), links with rld, runs sim.py --summary, and checks **r2** at halt
against the expected 12-bit word.

Run:
  python3 tools/tests/librcc/run_librcc_tests.py
  python3 tools/tests/librcc/run_librcc_tests.py --verbose
  python3 tools/tests/librcc/run_librcc_tests.py --filter 'div'

Wired into ``python3 run_tests.py --only librcc`` from the repo root.
"""

from __future__ import annotations

import argparse
import math
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "rrisc_toolchain.py").is_file())
sys.path.insert(0, str(ROOT))

from rrisc_toolchain import (  # noqa: E402
    lib_dir,
    python_exe,
    ras_emit_obj_cmd,
    resolve_ras,
    resolve_rld,
    rld_cmd,
    sim_py_path,
)


CODE_BASE = "0o1000"
DATA_BASE = "0o3000"
STACK_TOP = "0o3000"


def word12(x: int) -> int:
    return x & 0xFFF


def signed12(w: int) -> int:
    v = w & 0xFFF
    return v - 4096 if v > 2047 else v


def expect_div(r3w: int, r2w: int) -> int:
    """Truncating `/` toward zero (matches librcc __div)."""
    a = signed12(r3w)
    b = signed12(r2w)
    if b == 0:
        return 0
    q = math.trunc(a / b)
    return word12(q)


def expect_mod(r3w: int, r2w: int) -> int:
    """Remainder matching C `%` with truncating division."""
    a = signed12(r3w)
    b = signed12(r2w)
    if b == 0:
        return 0
    q = math.trunc(a / b)
    r = a - q * b
    return word12(r)


def oct_lit(w: int) -> str:
    """Octal literal for a 12-bit word (ras)."""
    return f"0o{(w & 0xFFF):o}"


def parse_r2(summary_stdout: str) -> int | None:
    """First line from ``sim.py --summary`` is like: ``T: 0 PC: ... r2: 0052 ...``."""
    for line in summary_stdout.splitlines():
        m = re.search(r"\br2:\s*([0-7]{4})\b", line)
        if m:
            return int(m.group(1), 8) & 0xFFF
    return None


def emit_main(sym: str, r3: int, r2: int) -> str:
    return f"""\
; generated — librcc harness case
%define RCC_CODE_BASE {CODE_BASE}
%define RCC_DATA_BASE {DATA_BASE}
%define RCC_STACK_TOP {STACK_TOP}

    .section text
    .global main
main:
    li r3, {oct_lit(r3)}
    li r2, {oct_lit(r2)}
    li r1, {sym}
    jalr r5, r1
    halt
"""


@dataclass(frozen=True)
class Case:
    name: str
    sym: str
    r3: int
    r2: int
    expect_r2: int


def all_cases() -> list[Case]:
    """Expected results match librcc.s / former Codegen semantics (12-bit wrap)."""
    return [
        # __mul
        Case("mul_6_7", "__mul", 6, 7, word12(6 * 7)),
        Case("mul_zero_a", "__mul", 0, 999, 0),
        Case("mul_wrap", "__mul", 2048, 2, word12(2048 * 2)),
        Case("mul_max", "__mul", 4095, 4095, word12(4095 * 4095)),
        # __udiv
        Case("udiv_simple", "__udiv", 100, 10, 10),
        Case("udiv_by_zero", "__udiv", 50, 0, 0),
        Case("udiv_one", "__udiv", 4095, 1, 4095),
        Case("udiv_small", "__udiv", 3, 7, 0),
        # __umod
        Case("umod_simple", "__umod", 17, 5, 2),
        Case("umod_by_zero", "__umod", 3, 0, 0),
        Case("umod_lt", "__umod", 4, 9, 4),
        # __div (signed 12-bit, trunc toward zero)
        Case("div_pos", "__div", 10, 3, expect_div(10, 3)),
        Case("div_neg_n", "__div", word12(-7), 3, expect_div(word12(-7), 3)),
        Case("div_neg_d", "__div", 12, word12(-3), expect_div(12, word12(-3))),
        Case("div_both_neg", "__div", word12(-12), word12(-5), expect_div(word12(-12), word12(-5))),
        Case("div_by_zero", "__div", 9, 0, 0),
        Case("div_large", "__div", 4000, 9, expect_div(4000, 9)),
        # __mod (C-style remainder with truncating /)
        Case("mod_pos", "__mod", 10, 3, expect_mod(10, 3)),
        Case("mod_neg_n", "__mod", word12(-7), 3, expect_mod(word12(-7), 3)),
        Case("mod_zero_d", "__mod", 4, 0, 0),
        Case("mod_unsigned_like", "__mod", 11, 4, expect_mod(11, 4)),
    ]


def link_one_case(
    *,
    ras: Path,
    rld: Path,
    lib: Path,
    tmp: Path,
    case: Case,
) -> tuple[bool, str]:
    user_s = tmp / "user.s"
    user_s.write_text(emit_main(case.sym, case.r3, case.r2), encoding="utf-8")

    crt0_s = ROOT / "lib" / "crt0.s"
    librcc_s = ROOT / "lib" / "librcc.s"
    crt0_o = tmp / "crt0.o"
    librcc_o = tmp / "librcc.o"
    user_o = tmp / "user.o"
    bin_path = tmp / "a.bin"

    r0 = subprocess.run(
        ras_emit_obj_cmd(ras, crt0_s, crt0_o, cli_defines=[("RCC_STACK_TOP", STACK_TOP)]),
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        check=False,
    )
    if r0.returncode != 0:
        return False, f"crt0.ras:\n{r0.stderr or r0.stdout}"

    ru = subprocess.run(
        ras_emit_obj_cmd(ras, user_s, user_o, include_dirs=[lib]),
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        check=False,
    )
    if ru.returncode != 0:
        return False, f"user.ras:\n{ru.stderr or ru.stdout}"

    rl = subprocess.run(
        ras_emit_obj_cmd(ras, librcc_s, librcc_o, include_dirs=[lib]),
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        check=False,
    )
    if rl.returncode != 0:
        return False, f"librcc.ras:\n{rl.stderr or rl.stdout}"

    rk = subprocess.run(
        rld_cmd(rld, [crt0_o, librcc_o, user_o], bin_path, code_base=CODE_BASE, data_base=DATA_BASE),
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        check=False,
    )
    if rk.returncode != 0:
        return False, f"rld:\n{rk.stderr or rk.stdout}"

    sim = subprocess.run(
        [
            python_exe(),
            str(sim_py_path(ROOT)),
            "--summary",
            "--start",
            CODE_BASE,
            "--maxcycle",
            "500000",
            str(bin_path),
        ],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        check=False,
    )
    if sim.returncode != 0:
        return False, f"sim exit {sim.returncode}:\n{sim.stderr or sim.stdout}"

    out = sim.stdout or ""
    got = parse_r2(out)
    if got is None:
        return False, f"could not parse r2 from sim stdout:\n{out}"
    if got != word12(case.expect_r2):
        return False, f"r2 want {word12(case.expect_r2):04o} got {got:04o}\n{out}"
    return True, ""


def main() -> int:
    ap = argparse.ArgumentParser(description="lib/librcc.s regression harness")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--filter", metavar="REGEX", help="only cases whose name matches")
    ap.add_argument("--ras", type=Path, metavar="PATH", help="override ras executable")
    ap.add_argument("--rld", type=Path, metavar="PATH", help="override rld executable")
    args = ap.parse_args()

    filt = re.compile(args.filter) if args.filter else None
    ras = resolve_ras(ROOT, str(args.ras) if args.ras else None)
    rld = resolve_rld(ROOT, str(args.rld) if args.rld else None)
    if not ras:
        print("librcc-tests: ras not found (build exe:ras in tools/)", file=sys.stderr)
        return 2
    if not rld:
        print("librcc-tests: rld not found (build exe:rld in tools/)", file=sys.stderr)
        return 2

    lib = lib_dir(ROOT)
    cases = [c for c in all_cases() if not filt or filt.search(c.name)]
    if not cases:
        print("librcc-tests: no cases selected", file=sys.stderr)
        return 1

    n_fail = 0
    with tempfile.TemporaryDirectory(prefix="rrisc-librcc-") as td:
        tmp = Path(td)
        for c in cases:
            ok, detail = link_one_case(ras=ras, rld=rld, lib=lib, tmp=tmp, case=c)
            if ok:
                if args.verbose:
                    print(f"PASS {c.name}", flush=True)
            else:
                n_fail += 1
                print(f"FAIL {c.name}", file=sys.stderr)
                print(detail, file=sys.stderr)

    if args.verbose or n_fail == 0:
        print(f"librcc-tests: {len(cases) - n_fail}/{len(cases)} passed", flush=True)
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
