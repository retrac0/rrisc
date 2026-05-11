#!/usr/bin/env python3
"""
Random stress tests for lib/float/*.s routines.

Reuses asm templates, assemble_and_run, and golden models from run_float_tests.py.
Does not fuzz __ftoa (exact ASCII oracle would duplicate __ftoa.s); see plan.

__atof inputs are drawn conservatively (modest magnitudes) so they stay within what
__atof.s digit accumulation handles; arbitrary decimals can mismatch Python float(s).
Four-word results accept bit-identical output or equal float48.to_float (including ±0).

Examples:
  python3 tools/tests/float/fuzz_float_routines.py -n 5000 --seed 1
  python3 tools/tests/float/fuzz_float_routines.py --routine __fmul,__fdiv -n 2000
"""

from __future__ import annotations

import argparse
import math
import random
import sys
import tempfile
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "rrisc_toolchain.py").is_file())
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_float_tests as ft  # noqa: E402

import pytools.float48 as f48  # noqa: E402

# All float routines except __ftoa (no stable Python oracle without mirroring asm).
DEFAULT_ROUTINES = (
    "__fcopy",
    "__fneg",
    "__fadd",
    "__fsub",
    "__fmul",
    "__fdiv",
    "__itof",
    "__ftoi",
    "__fcmp",
    "__atof",
)

BINOP_OPS: dict[str, tuple[str, str]] = {
    "__fadd": ("__fadd", "+"),
    "__fsub": ("__fsub", "-"),
    "__fmul": ("__fmul", "*"),
    "__fdiv": ("__fdiv", "/"),
}


def output_matches(got: str, err: str, case: ft.Case) -> bool:
    """Same acceptance as tools/tests/float/run_float_tests.py main(), plus float equality for four words.

    Hex may differ for ±0.0 (oracle vs asm); Python float compares +0.0 == -0.0."""
    if err:
        return False
    got = got.strip()
    if got == case.expected:
        return True
    if got.count(" ") == 3:
        try:
            got_words = tuple(int(t, 16) for t in got.split())
            exp_words = tuple(int(t, 16) for t in case.expected.split())
            if f48.to_float(got_words) == f48.to_float(exp_words):
                return True
        except (ValueError, OverflowError):
            pass
    if not err and case.rel_tol > 0 and got.count(" ") == 3:
        try:
            got_words = tuple(int(t, 16) for t in got.split())
            exp_words = tuple(int(t, 16) for t in case.expected.split())
            gv = f48.to_float(got_words)
            ev = f48.to_float(exp_words)
            if math.isclose(gv, ev, rel_tol=case.rel_tol, abs_tol=0):
                return True
            if gv == 0.0 and ev == 0.0:
                return True
        except (ValueError, OverflowError):
            pass
    return False


def _classify_zero_words(words: tuple[int, ...]) -> bool:
    _, e, sig = f48.unpack(words)
    return f48.classify(e, sig) == "zero"


def sample_float(rng: random.Random) -> float:
    """Bias toward edges and powers of two; mostly finite scalars."""
    r = rng.random()
    if r < 0.12:
        return rng.choice(
            (
                0.0,
                1.0,
                -1.0,
                2.0,
                -2.0,
                0.5,
                -0.5,
                12.5,
                100.0,
                -100.0,
                2047.0,
                -2048.0,
                1e-6,
                1e6,
            )
        )
    if r < 0.24:
        return math.ldexp(1.0, rng.randint(-25, 25)) * (
            1.0 if rng.random() < 0.5 else -1.0
        )
    return rng.uniform(-3500.0, 3500.0)


def sample_pair(rng: random.Random) -> tuple[float, float]:
    return sample_float(rng), sample_float(rng)


def random_atof_string(rng: random.Random, max_len: int = 12) -> str:
    """Decimal strings for __atof: stay in a modest range so digit accumulation matches Python float(s).

    Unbounded integers (e.g. '8412') can overflow __atof.s intermediates; keep |value| modest."""
    for _ in range(40):
        if rng.random() < 0.5:
            n = rng.randint(-2048, 2047)
            s = str(n)
        else:
            ip = rng.randint(0, 100)
            fp = rng.randint(0, 9999)
            s = f"{ip}.{fp:04d}"
        if len(s) > max_len:
            s = s[:max_len].rstrip(".")
        try:
            v = float(s)
        except ValueError:
            continue
        if abs(v) <= 4096.0 and math.isfinite(v):
            return s
    return "0"


def build_case(
    rng: random.Random,
    iteration: int,
    routine: str,
) -> ft.Case:
    tag = f"fuzz-{iteration}-{routine}"

    if routine in BINOP_OPS:
        rname, op = BINOP_OPS[routine]
        for _ in range(50):
            x, y = sample_pair(rng)
            a = f48.from_float(x)
            b = f48.from_float(y)
            if routine == "__fdiv" and _classify_zero_words(b):
                continue
            return ft._bin_op(tag, rname, op, x, y)
        # fallback if RNG keeps zero divisor
        return ft._bin_op(tag, rname, op, 1.0, 2.0)

    if routine == "__fcopy":
        x = sample_float(rng)
        a = f48.from_float(x)
        return ft.Case(
            name=tag,
            asm=ft.asm_unop("__fcopy", a),
            expected=ft.hex_words(a),
            note=f"identity {x!r}",
        )

    if routine == "__fneg":
        x = sample_float(rng)
        a = f48.from_float(x)
        s, e, sig = f48.unpack(a)
        r = f48.pack(s ^ 1, e, sig)
        return ft.Case(
            name=tag,
            asm=ft.asm_unop("__fneg", a),
            expected=ft.hex_words(r),
            note=f"- {x!r}",
        )

    if routine == "__itof":
        n = rng.randint(0, 0xFFF)
        return ft._itof_case(tag, n)

    if routine == "__ftoi":
        x = sample_float(rng)
        return ft._ftoi_case(tag, x)

    if routine == "__fcmp":
        x, y = sample_pair(rng)
        return ft._fcmp_case(tag, x, y)

    if routine == "__atof":
        s = random_atof_string(rng)
        return ft._atof_case(tag, s)

    raise AssertionError(f"unsupported routine {routine!r}")


def parse_routines(arg: str | None, default: tuple[str, ...]) -> tuple[str, ...]:
    if not arg:
        return default
    names = tuple(x.strip() for x in arg.split(",") if x.strip())
    for n in names:
        if n not in default and n != "__ftoa":
            print(f"unknown routine {n!r} (allowed: {', '.join(default)})", file=sys.stderr)
            sys.exit(2)
        if n == "__ftoa":
            print("__ftoa is not supported by this fuzzer (no oracle)", file=sys.stderr)
            sys.exit(2)
    return names


def main() -> int:
    ap = argparse.ArgumentParser(description="RRISC float runtime fuzzer")
    ap.add_argument("-n", "--iterations", type=int, default=1000, metavar="N")
    ap.add_argument(
        "--seed",
        type=int,
        default=None,
        help="RNG seed (default: derive from time for exploratory runs)",
    )
    ap.add_argument(
        "--routine",
        metavar="NAME,...",
        help=f"comma-separated subset (default: all except __ftoa). Choices: {', '.join(DEFAULT_ROUTINES)}",
    )
    ap.add_argument(
        "--fail-fast",
        action="store_true",
        help="stop on first mismatch or toolchain error",
    )
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--keep", action="store_true")
    args = ap.parse_args()

    routines = parse_routines(args.routine, DEFAULT_ROUTINES)
    if not routines:
        print("no routines selected", file=sys.stderr)
        return 2

    seed = args.seed
    if seed is None:
        import time

        seed = int(time.time_ns() % (2**32))
        print(f"float-fuzz: auto seed={seed} (pass --seed {seed} to replay)", file=sys.stderr)
    rng = random.Random(seed)

    work = Path(tempfile.mkdtemp(prefix="rrisc-float-fuzz-"))
    fails: list[tuple[int, str, ft.Case, str, str, str]] = []
    n_ok = 0
    n_ran = 0

    try:
        for i in range(args.iterations):
            routine = rng.choice(routines)
            case = build_case(rng, i, routine)
            out, err = ft.assemble_and_run(case.asm, work, i)
            ok = output_matches(out, err, case)
            if ok:
                n_ok += 1
                if args.verbose:
                    print(f"[ok]   {case.name}: {out.strip()!r}")
            else:
                fails.append((i, routine, case, out.strip(), case.expected, err))
                print(f"[FAIL] {case.name}")
                if case.note:
                    print(f"        note: {case.note}")
                print(f"        expected: {case.expected!r}")
                print(f"        got:      {out.strip()!r}")
                if err:
                    print(f"        stderr/toolchain: {err.strip()}")
                print(f"        (iteration={i} seed={seed} routine={routine})")
                if args.fail_fast:
                    n_ran = i + 1
                    break
            n_ran = i + 1
    finally:
        if not args.keep:
            for p in work.glob("*"):
                try:
                    p.unlink()
                except OSError:
                    pass
            try:
                work.rmdir()
            except OSError:
                pass
        else:
            print(f"build dir kept at {work}", file=sys.stderr)

    print(f"\nfloat-fuzz: seed={seed} {n_ok}/{n_ran} ok, {len(fails)} fail")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
