#!/usr/bin/env python3
"""
Float runtime regression harness for lib/float/*.s.

For each case we synthesise a small RRISC asm program that:
  1. Lays the operand cells in the .org 0o0100 page (raw 12-bit words from
     float48.from_float).
  2. Calls one runtime routine.
  3. Dumps the result via lib/float/put_hex12.s, separated by spaces.
  4. halts.

The expected UART output is computed in Python using float48.py (the bit-level
reference model) so a discrepancy means the asm is wrong, not the harness.

Run:
  python3 tools/tests/float/run_float_tests.py
  python3 tools/tests/float/run_float_tests.py --verbose
  python3 tools/tests/float/run_float_tests.py --filter fmul

The harness is also wired into run_tests.py as the `float` suite.
"""

from __future__ import annotations

import argparse
import math
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "rrisc_toolchain.py").is_file())
sys.path.insert(0, str(ROOT))

from rrisc_toolchain import lib_dir, py_asm_cmd, python_exe, sim_py_path  # noqa: E402

import float48 as f48  # noqa: E402


# -- helpers ------------------------------------------------------------------

# Float source files each routine pulls in. The driver %includes these in
# order at the bottom of every test program so labels resolve once. (Asm
# %include is one-shot per path.)
#
# NOTE: The float routines share a couple of tiny “store result” helpers
# (`__fstore_zero`, `__fstore_inf`) that live in `float/_float_store_helpers.s`.
# The production build pulls them in via `lib/float/rrisc_float_bundle.s`, but
# the regression harness assembles routines in isolation, so we must include
# that helper explicitly here.
COMMON_FLOAT_DEPS = ["float/_float_store_helpers.s", "float/_float_pack_helpers.s"]
ROUTINE_DEPS: dict[str, list[str]] = {
    "__fadd":  [*COMMON_FLOAT_DEPS, "float/__fcopy.s", "float/__fadd.s"],
    "__fsub":  [*COMMON_FLOAT_DEPS, "float/__fcopy.s", "float/__fadd.s", "float/__fsub.s"],
    "__fmul":  [*COMMON_FLOAT_DEPS, "float/__fmul.s"],
    "__fdiv":  [*COMMON_FLOAT_DEPS, "float/__fdiv.s"],
    "__fcmp":  [*COMMON_FLOAT_DEPS, "float/__fcmp.s"],
    "__fcopy": [*COMMON_FLOAT_DEPS, "float/__fcopy.s"],
    "__fneg":  [*COMMON_FLOAT_DEPS, "float/__fneg.s"],
    "__ftoi":  [*COMMON_FLOAT_DEPS, "float/__ftoi.s"],
    "__itof":  [*COMMON_FLOAT_DEPS, "float/__itof.s"],
    "__atof": [
        *COMMON_FLOAT_DEPS,
        "float/__itof.s", "float/__fadd.s", "float/__fmul.s",
        "float/__fdiv.s", "float/__fneg.s", "float/__fcopy.s",
        "float/__atof.s",
    ],
    "__ftoa": [
        *COMMON_FLOAT_DEPS,
        "float/__fcopy.s", "float/__fneg.s", "float/__ftoi.s",
        "float/__itof.s", "float/__fadd.s", "float/__fsub.s",
        "float/__fmul.s", "itoa.s", "float/__ftoa.s",
    ],
}


def _hex_n(n: int) -> str:
    # put_hex12.s emits exactly three hex digits (lower case).
    return f"0x{n & 0xFFF:03x}"


def hex_words(words: tuple[int, int, int, int]) -> str:
    return " ".join(_hex_n(w) for w in words)


# -- assembly templates -------------------------------------------------------

DUMP4_TEMPLATE = """\
    li   r4, {label}
    lwr  r2, r4
    li   r1, put_hex12
    jalr r5, r1
    li   r2, spc
    li   r1, putstr
    jalr r5, r1

    li   r4, {label}
    addi r4, 1
    lwr  r2, r4
    li   r1, put_hex12
    jalr r5, r1
    li   r2, spc
    li   r1, putstr
    jalr r5, r1

    li   r4, {label}
    addi r4, 2
    lwr  r2, r4
    li   r1, put_hex12
    jalr r5, r1
    li   r2, spc
    li   r1, putstr
    jalr r5, r1

    li   r4, {label}
    addi r4, 3
    lwr  r2, r4
    li   r1, put_hex12
    jalr r5, r1
"""


def dump_int_block() -> str:
    """Print r2 (12-bit) as 0xNNN."""
    return (
        "    li   r1, put_hex12\n"
        "    jalr r5, r1\n"
    )


def common_data() -> str:
    return (
        "spc: .unicode \" \"\n"
        "     .word 0\n"
    )


def common_includes(routine: str) -> str:
    """Includes for the bottom of the program."""
    deps = "\n".join(f'%include "{p}"' for p in ROUTINE_DEPS[routine])
    return (
        '%include "io/putchar.s"\n'
        '%include "io/putstr.s"\n'
        '%include "float/put_hex12.s"\n'
        f"{deps}\n"
    )


def asm_binop(routine: str, a_words: tuple[int, ...], b_words: tuple[int, ...]) -> str:
    """Program that calls routine(fr, fa, fb) and dumps fr as 4 cells."""
    a = ", ".join(str(w) for w in a_words)
    b = ", ".join(str(w) for w in b_words)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fa:  .word {a}
fb:  .word {b}
fr:  .fill 4, 0
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fr
    li   r3, fa
    li   r4, fb
    li   r1, {routine}
    jalr r5, r1
{DUMP4_TEMPLATE.format(label="fr")}    halt

{common_includes(routine)}"""


def asm_unop(routine: str, a_words: tuple[int, ...]) -> str:
    """Program that calls routine(fr, fa) and dumps fr as 4 cells."""
    a = ", ".join(str(w) for w in a_words)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fa:  .word {a}
fr:  .fill 4, 0
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fr
    li   r3, fa
    li   r1, {routine}
    jalr r5, r1
{DUMP4_TEMPLATE.format(label="fr")}    halt

{common_includes(routine)}"""


def asm_itof(value: int) -> str:
    """Program that calls __itof(fr, value) and dumps fr."""
    v = value & 0xFFF
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fr:  .fill 4, 0
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fr
    li   r3, {v}
    li   r1, __itof
    jalr r5, r1
{DUMP4_TEMPLATE.format(label="fr")}    halt

{common_includes("__itof")}"""


def asm_ftoi(a_words: tuple[int, ...]) -> str:
    """Program that calls __ftoi(fa) and dumps r2 as a single hex int."""
    a = ", ".join(str(w) for w in a_words)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fa:  .word {a}
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fa
    li   r1, __ftoi
    jalr r5, r1
{dump_int_block()}    halt

{common_includes("__ftoi")}"""


def asm_fcmp(a_words: tuple[int, ...], b_words: tuple[int, ...]) -> str:
    a = ", ".join(str(w) for w in a_words)
    b = ", ".join(str(w) for w in b_words)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fa:  .word {a}
fb:  .word {b}
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fa
    li   r3, fb
    li   r1, __fcmp
    jalr r5, r1
{dump_int_block()}    halt

{common_includes("__fcmp")}"""


def asm_atof(s: str) -> str:
    """Program that parses the string s with __atof and dumps the float cells."""
    bytes_ = list(s.encode("ascii")) + [0]
    words = ", ".join(str(b) for b in bytes_)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
src: .word {words}
fr:  .fill 4, 0
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, src
    li   r3, fr
    li   r1, __atof
    jalr r5, r1
{DUMP4_TEMPLATE.format(label="fr")}    halt

{common_includes("__atof")}"""


def asm_ftoa(a_words: tuple[int, ...]) -> str:
    """Program that converts fa to ASCII via __ftoa and prints the buffer.

    __ftoa writes a NUL-terminated word string and returns r2 = ptr to NUL.
    We call putstr right after, which walks the string until the NUL.
    """
    a = ", ".join(str(w) for w in a_words)
    return f"""\
%include "macros/uart_tx.inc"

    .org 0o0100
fa:   .word {a}
buf:  .fill 16, 0
{common_data()}
    .org 0o1000
_start:
    li   r6, 0o7770
    li   r2, fa
    li   r3, buf
    li   r1, __ftoa
    jalr r5, r1
    li   r2, buf
    li   r1, putstr
    jalr r5, r1
    halt

{common_includes("__ftoa")}"""


# -- runner ------------------------------------------------------------------

@dataclass
class Case:
    name: str
    asm: str
    expected: str
    note: str = ""
    # If set, compare the four output cells numerically (via to_float) with
    # this relative tolerance; lets us tolerate the documented sig_hi-only
    # precision compounding through __atof / __fmul / __fdiv chains.
    rel_tol: float = 0.0


@dataclass
class Outcome:
    name: str
    ok: bool
    expected: str
    got: str
    err: str = ""
    note: str = ""


def assemble_and_run(asm_text: str, work: Path, idx: int) -> tuple[str, str]:
    s = work / f"t{idx}.s"
    s.write_text(asm_text)
    bin_path = work / f"t{idx}.bin"
    cp = subprocess.run(
        py_asm_cmd(ROOT, src=s, out=bin_path, include_dirs=[lib_dir(ROOT)]),
        capture_output=True,
    )
    if cp.returncode:
        return "", "asm: " + cp.stderr.decode("utf-8", "replace")
    cp = subprocess.run(
        [
            python_exe(), str(sim_py_path(ROOT)),
            "--terminal",
            "--start", "0o1000",
            "--mem", "ram:0:0o7770",
            "--maxcycle", "20000000",
            str(bin_path),
        ],
        capture_output=True,
        timeout=120,
    )
    if cp.returncode:
        return cp.stdout.decode("utf-8", "replace"), \
               "sim: " + cp.stderr.decode("utf-8", "replace")
    return cp.stdout.decode("utf-8", "replace"), ""


# -- case construction --------------------------------------------------------

def _low_prec_fdiv(a: tuple[int, ...], b: tuple[int, ...]) -> tuple[int, int, int, int]:
    """Match lib/float/__fdiv.s: q = floor((a_hi << 11) / b_hi); low words zero."""
    sa, ea, siga = f48.unpack(a)
    sb, eb, sigb = f48.unpack(b)
    s = sa ^ sb
    ca, cb = f48.classify(ea, siga), f48.classify(eb, sigb)
    if ca == "nan" or cb == "nan" or (ca == "inf" and cb == "inf") or (ca == "zero" and cb == "zero"):
        return f48.pack(0, f48.EXP_INF, f48.LEAD_BIT)
    if cb == "zero" or ca == "inf":
        return f48.pack(s, f48.EXP_INF, 0)
    if ca == "zero" or cb == "inf":
        return f48.pack(s, 0, 0)
    a_hi = (siga >> 24) & 0xFFF
    b_hi = (sigb >> 24) & 0xFFF
    q = (a_hi << 11) // b_hi
    if q & (1 << 11):
        exp = ea - eb + f48.BIAS
    else:
        q <<= 1
        exp = ea - eb + f48.BIAS - 1
    if exp >= f48.EXP_INF:
        return f48.pack(s, f48.EXP_INF, 0)
    if exp <= 0:
        return f48.pack(s, 0, 0)
    return f48.pack(s, exp, (q & 0xFFF) << 24)


def _low_prec_fmul(a: tuple[int, ...], b: tuple[int, ...]) -> tuple[int, int, int, int]:
    """Match lib/float/__fmul.s: 12x12 -> 24-bit product; low word zero."""
    sa, ea, siga = f48.unpack(a)
    sb, eb, sigb = f48.unpack(b)
    s = sa ^ sb
    ca, cb = f48.classify(ea, siga), f48.classify(eb, sigb)
    if ca == "nan" or cb == "nan":
        return f48.pack(0, f48.EXP_INF, f48.LEAD_BIT)
    if (ca == "zero" and cb == "inf") or (ca == "inf" and cb == "zero"):
        return f48.pack(0, f48.EXP_INF, f48.LEAD_BIT)
    if ca == "inf" or cb == "inf":
        return f48.pack(s, f48.EXP_INF, 0)
    if ca == "zero" or cb == "zero":
        return f48.pack(s, 0, 0)
    a_hi = (siga >> 24) & 0xFFF
    b_hi = (sigb >> 24) & 0xFFF
    p = a_hi * b_hi  # 24-bit
    if p & (1 << 23):
        exp = ea + eb - f48.BIAS + 1
    else:
        p <<= 1
        exp = ea + eb - f48.BIAS
    if exp >= f48.EXP_INF:
        return f48.pack(s, f48.EXP_INF, 0)
    if exp <= 0:
        return f48.pack(s, 0, 0)
    sig_hi = (p >> 12) & 0xFFF
    sig_mid = p & 0xFFF
    return (((s & 1) << 11) | (exp & 0x7FF), sig_hi, sig_mid, 0)


def _bin_op(name: str, routine: str, op: str, x: float, y: float) -> Case:
    a = f48.from_float(x)
    b = f48.from_float(y)
    if op == "*":
        r = _low_prec_fmul(a, b)
        note_extra = "  [sig_hi-only mul model]"
    elif op == "/":
        r = _low_prec_fdiv(a, b)
        note_extra = "  [sig_hi-only div model]"
    else:
        table = {"+": f48.fadd_bits, "-": f48.fsub_bits}
        r = table[op](a, b)
        note_extra = ""
    return Case(
        name=name,
        asm=asm_binop(routine, a, b),
        expected=hex_words(r),
        note=f"{x!r} {op} {y!r}  golden={f48.format_words(r)}{note_extra}",
    )


def _itof_case(name: str, n: int) -> Case:
    n12 = n & 0xFFF
    # 12-bit signed interpretation:
    signed = n12 if n12 < 0x800 else n12 - 0x1000
    expected_w = f48.from_float(float(signed))
    return Case(
        name=name,
        asm=asm_itof(n12),
        expected=hex_words(expected_w),
        note=f"int {signed} -> float {f48.format_words(expected_w)}",
    )


def _ftoi_case(name: str, x: float) -> Case:
    a = f48.from_float(x)
    # __ftoi operates on sig_hi (top 12 bits) only -- ~12-bit precision is all
    # that fits in a 12-bit signed result. value ~= sig_hi * 2^(exp - BIAS - 11).
    sign, exp_raw, sig = f48.unpack(a)
    if exp_raw == 0 or exp_raw == f48.EXP_INF:
        truncated = 0
    else:
        sig_hi = (sig >> 24) & 0xFFF
        shift = exp_raw - 1035  # exp - BIAS - 11
        if shift >= 12 or shift <= -12:
            truncated = 0
        elif shift >= 0:
            truncated = (sig_hi << shift) & 0xFFF
        else:
            truncated = (sig_hi >> -shift) & 0xFFF
        if sign and truncated:
            truncated = (-truncated) & 0xFFF
    return Case(
        name=name,
        asm=asm_ftoi(a),
        expected=_hex_n(truncated),
        note=f"trunc {x!r} -> {truncated} (sig_hi-only model)",
    )


def _fcmp_case(name: str, x: float, y: float) -> Case:
    a = f48.from_float(x)
    b = f48.from_float(y)
    if math.isnan(x) or math.isnan(y):
        want = 0
    elif x < y:
        want = -1
    elif x > y:
        want = 1
    else:
        want = 0
    return Case(
        name=name,
        asm=asm_fcmp(a, b),
        expected=_hex_n(want & 0xFFF),
        note=f"cmp {x!r} ? {y!r} = {want}",
    )


def _atof_case(name: str, s: str) -> Case:
    # __atof chains __itof/__fmul/__fdiv/__fadd, so each fractional digit can
    # cost ~1 ulp at sig_hi precision; allow that tolerance numerically.
    return Case(
        name=name,
        asm=asm_atof(s),
        expected=hex_words(f48.from_float(float(s))),
        note=f"parse {s!r}",
        rel_tol=2 ** -10,
    )


def _ftoa_case(name: str, x: float, expected: str) -> Case:
    return Case(
        name=name,
        asm=asm_ftoa(f48.from_float(x)),
        expected=expected,
        note=f"format {x!r} -> {expected!r}",
    )


def build_cases() -> list[Case]:
    cs: list[Case] = []

    # __fcopy: bit-exact identity for any cells.
    for x in (1.0, -1.0, 12.5, 0.0, -0.0, 1e6, 1e-6):
        a = f48.from_float(x)
        cs.append(Case(
            name=f"fcopy:{x!r}",
            asm=asm_unop("__fcopy", a),
            expected=hex_words(a),
            note=f"identity copy of {x!r}",
        ))

    # __fneg: bit-exact sign flip.
    for x in (1.0, -1.0, 12.5, 1e6):
        a = f48.from_float(x)
        s, e, sig = f48.unpack(a)
        r = f48.pack(s ^ 1, e, sig)
        cs.append(Case(
            name=f"fneg:{x!r}",
            asm=asm_unop("__fneg", a),
            expected=hex_words(r),
            note=f"-{x!r}",
        ))

    # __fadd / __fsub / __fmul / __fdiv: small set that exercises the model.
    pairs = [
        (1.0, 2.0),
        (3.0, 4.0),
        (100.5, 0.5),
        (1.0, -1.0),
        (-2.5, 7.5),
        (1.5, 1.5),
        (12.5, 0.5),
        (0.5, 2.0),
        (1.0, 1.0),
    ]
    for x, y in pairs:
        cs.append(_bin_op(f"fadd:{x!r}+{y!r}", "__fadd", "+", x, y))
        cs.append(_bin_op(f"fsub:{x!r}-{y!r}", "__fsub", "-", x, y))
        cs.append(_bin_op(f"fmul:{x!r}*{y!r}", "__fmul", "*", x, y))
        if y != 0.0:
            cs.append(_bin_op(f"fdiv:{x!r}/{y!r}", "__fdiv", "/", x, y))

    # zero / sign cases
    cs.append(_bin_op("fadd:0+5", "__fadd", "+", 0.0, 5.0))
    cs.append(_bin_op("fadd:5+0", "__fadd", "+", 5.0, 0.0))
    cs.append(_bin_op("fadd:1+(-1)cancel", "__fadd", "+", 1.0, -1.0))

    # __itof: small ints, including signed extremes.
    for n in (0, 1, -1, 7, -7, 100, -100, 2047, -2048):
        cs.append(_itof_case(f"itof:{n}", n))

    # __ftoi: truncating conversions, tested against the sig_hi-only model the
    # routine actually implements.
    for x in (0.0, 1.0, -1.0, 12.5, -12.5, 100.0, -100.0, 2047.0, -2048.0):
        cs.append(_ftoi_case(f"ftoi:{x!r}", x))

    # __fcmp
    for x, y in [(1.0, 2.0), (2.0, 1.0), (1.0, 1.0), (0.0, 0.0),
                 (-1.0, 1.0), (1.0, -1.0), (-2.0, -3.0), (12.5, 12.5)]:
        cs.append(_fcmp_case(f"fcmp:{x!r}?{y!r}", x, y))

    # __atof: parse representative decimal strings.
    for s in ("0", "0.0", "1", "1.0", "12.5", "-12.5", "0.5", "-0.5",
              "100", "0.0625"):
        cs.append(_atof_case(f"atof:{s}", s))

    # __ftoa: 4 fractional digits, sign, leading int, trailing zeros for
    # exact-representable decimals (these are what the routine guarantees).
    cs.append(_ftoa_case("ftoa:0",     0.0,  "0.0000"))
    cs.append(_ftoa_case("ftoa:1",     1.0,  "1.0000"))
    cs.append(_ftoa_case("ftoa:-1",   -1.0, "-1.0000"))
    cs.append(_ftoa_case("ftoa:12.5", 12.5, "12.5000"))
    cs.append(_ftoa_case("ftoa:0.5",   0.5,  "0.5000"))

    return cs


# -- main ---------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="RRISC float runtime regression")
    ap.add_argument("--filter", metavar="REGEX", help="only cases whose name matches")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="print every case (not just failures)")
    ap.add_argument("--keep", action="store_true",
                    help="leave the temporary build dir in place")
    args = ap.parse_args()

    cases = build_cases()
    if args.filter:
        rx = re.compile(args.filter)
        cases = [c for c in cases if rx.search(c.name)]
    if not cases:
        print("no cases matched", file=sys.stderr)
        return 2

    work = Path(tempfile.mkdtemp(prefix="rrisc-float-"))
    fails: list[Outcome] = []
    n_ok = 0
    for i, case in enumerate(cases):
        out, err = assemble_and_run(case.asm, work, i)
        got = out.strip()
        ok = (not err) and got == case.expected
        if not ok and not err and case.rel_tol > 0 and got.count(" ") == 3:
            try:
                got_words = tuple(int(t, 16) for t in got.split())
                exp_words = tuple(int(t, 16) for t in case.expected.split())
                gv = f48.to_float(got_words)
                ev = f48.to_float(exp_words)
                if math.isclose(gv, ev, rel_tol=case.rel_tol, abs_tol=0):
                    ok = True
                elif gv == 0.0 and ev == 0.0:
                    ok = True
            except (ValueError, OverflowError):
                pass
        if ok:
            n_ok += 1
            if args.verbose:
                print(f"[ok]   {case.name}: {got}")
        else:
            o = Outcome(name=case.name, ok=False, expected=case.expected,
                        got=got, err=err, note=case.note)
            fails.append(o)
            print(f"[FAIL] {case.name}")
            if case.note:
                print(f"        note: {case.note}")
            print(f"        expected: {case.expected!r}")
            print(f"        got:      {got!r}")
            if err:
                print(f"        stderr:   {err.strip()}")

    if not args.keep:
        # cheap sweep; ignore errors
        for p in work.glob("*"):
            try: p.unlink()
            except OSError: pass
        try: work.rmdir()
        except OSError: pass
    else:
        print(f"build dir kept at {work}")

    total = len(cases)
    print(f"\nfloat: {n_ok}/{total} ok, {len(fails)} fail")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
