#!/usr/bin/env python3
"""
Unified RRISC test runner: RCC compiler tests, flat-assembler tests, and examples.

Replaces compiler/run_tests.sh and runtests.sh with one subprocess-based harness:
  - Correct argv handling (no shell splitting bugs)
  - Optional matrix over the Haskell assembler (default) and deprecated Python asm.py
    plus Python, C, and Haskell (rsim) simulators by default; use --simulators to trim
  - Parallel execution via ThreadPoolExecutor

Run from the repository root:

  python3 run_tests.py
  python3 run_tests.py --filter 'fib'
  python3 run_tests.py --jobs 8 --skip-unavailable
  python3 run_tests.py --bless-asm

Golden UART tests (manual expectations; never run --bless-output on these):
  compiler/tests/io/*.stdout.expect — compare simulator terminal + host gcc stdout.
"""

from __future__ import annotations

import argparse
import difflib
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path
from typing import Sequence, TextIO

from rrisc_toolchain import (
    IO_RCC_EXTRA_DEFAULT,
    IO_SIM_EXTRA_DEFAULT,
    asm_py_path,
    hsasm_cmd,
    hsasm_emit_obj_cmd,
    hsld_cmd,
    lib_dir,
    parse_flags_file,
    parse_rcc_defines,
    py_asm_cmd,
    python_exe,
    repo_root,
    rcc_src_arg,
    resolve_gcc,
    resolve_hsasm,
    resolve_hsld,
    resolve_rcc,
    resolve_rsim,
    resolve_sim2,
    sim_py_path,
)

PY_ASM_IN_MATRIX_DEPRECATION = (
    "run_tests: warning: --assemblers py (asm.py) is deprecated; "
    "use hsasm (default --assemblers hs). Example: cabal run hsasm -- from hstools/."
)


def _stderr_without_py_asm_deprecation(stderr: str) -> str:
    """asm.py prints a one-line deprecation to stderr before diagnostics; strip it for golden compares."""
    lines = stderr.splitlines(keepends=True)
    if lines and lines[0].startswith("asm.py:") and "deprecated" in lines[0]:
        return "".join(lines[1:])
    return stderr


# --- subprocess helpers ----------------------------------------------------

def run_capture(
    argv: Sequence[str],
    *,
    cwd: Path | None = None,
    stdin_path: Path | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    # Do not inherit the harness stdin (None): simulators with --terminal spawn a stdin
    # reader thread; inheriting an interactive TTY blocks until the user types. DEVNULL
    # gives immediate EOF so those threads exit and the child can finish cleanly.
    if stdin_path:
        stdin_f = open(stdin_path, "r", encoding="utf-8")
        stdin_arg: int | TextIO = stdin_f
    else:
        stdin_f = None
        stdin_arg = subprocess.DEVNULL
    try:
        return subprocess.run(
            list(argv),
            cwd=cwd,
            stdin=stdin_arg,
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )
    finally:
        if stdin_f:
            stdin_f.close()


def diff_text(a: str, b: str, a_name: str, b_name: str) -> str:
    return "".join(
        difflib.unified_diff(
            a.splitlines(True),
            b.splitlines(True),
            fromfile=a_name,
            tofile=b_name,
        )
    )


def emit_verbose(cfg: RunConfig, results: Sequence[TResult]) -> None:
    """Print per-check status as tests finish (stdout, flushed)."""
    if not cfg.verbose:
        return
    for r in results:
        tag = "PASS" if r.ok else "FAIL"
        sub = f" [{r.sub}]" if r.sub else ""
        print(f"{tag} {r.name}{sub}", flush=True)
        if not r.ok and r.detail:
            print(r.detail, flush=True)


# --- result types ----------------------------------------------------------

@dataclass
class TResult:
    ok: bool
    name: str
    detail: str = ""
    sub: str = ""  # e.g. "pyasm/csim"


@dataclass
class RunConfig:
    root: Path
    jobs: int
    filter_re: re.Pattern[str] | None
    assemblers: tuple[str, ...]  # "py", "hs"
    simulators: tuple[str, ...]  # "py", "c", "hs"
    skip_unavailable: bool
    verbose: bool
    keep_temps: bool
    rcc_path: Path | None
    hsasm_path: Path | None
    hsld_path: Path | None
    sim2_path: Path | None
    rsim_path: Path | None
    default_rcc_flags: list[str] = field(default_factory=lambda: ["--optimize"])
    compiler_sim_base: list[str] = field(
        default_factory=lambda: ["--summary", "--start", "0o1000", "--maxcycle", "500000"]
    )
    asm_test_maxcycle: int = 200_000


def sim_runner_base(cfg: RunConfig, rcc_defs: dict[str, str]) -> list[str]:
    """Argv prefix for simulators: `--start` follows RCC_CODE_BASE from the linked image."""
    start = rcc_defs.get("RCC_CODE_BASE", "0o1000")
    maxcycle = "500000"
    b = cfg.compiler_sim_base
    for i, x in enumerate(b):
        if x == "--maxcycle" and i + 1 < len(b):
            maxcycle = b[i + 1]
            break
    return ["--summary", "--start", start, "--maxcycle", maxcycle]


def replace_argv_flag(argv: list[str], flag: str, value: str) -> list[str]:
    """Replace `--flag <value>` if present; otherwise append `--flag value`."""
    out: list[str] = []
    i = 0
    replaced = False
    while i < len(argv):
        if argv[i] == flag and i + 1 < len(argv):
            out.extend([flag, value])
            i += 2
            replaced = True
        else:
            out.append(argv[i])
            i += 1
    if not replaced:
        out.extend([flag, value])
    return out


# --- RCC tests -------------------------------------------------------------

def run_rcc_error_test(cfg: RunConfig, src: Path) -> TResult:
    base = src.stem
    expect = cfg.root / "compiler" / "tests" / f"{base}.err.expect"
    rcc = cfg.rcc_path
    if not rcc:
        return TResult(False, f"rccerr:{base}", "rcc not found (build with: cd compiler && cabal build exe:rcc)")
    flags = list(cfg.default_rcc_flags)
    r = run_capture(
        [str(rcc), *flags, rcc_src_arg(cfg.root, src), "-o", os.devnull],
        cwd=cfg.root / "compiler",
    )
    if r.returncode == 0:
        return TResult(False, f"rccerr:{base}", "compiler accepted invalid program")
    if not expect.is_file():
        return TResult(True, f"rccerr:{base}", "(no .err.expect; skipped compare)")
    err = r.stderr or ""
    exp = expect.read_text(encoding="utf-8")
    if err != exp:
        return TResult(
            False,
            f"rccerr:{base}",
            diff_text(exp, err, str(expect), "stderr"),
        )
    return TResult(True, f"rccerr:{base}")


def run_rcc_success_test(cfg: RunConfig, src: Path, tmp_root: Path) -> list[TResult]:
    """Compile once, assemble with each backend, simulate with each backend."""
    base = src.stem
    name = f"rcc:{base}"
    results: list[TResult] = []
    compiler_tests = cfg.root / "compiler" / "tests"
    rcc = cfg.rcc_path
    if not rcc:
        return [
            TResult(False, name, "rcc not found (build with: cd compiler && cabal build exe:rcc)")
        ]

    per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
    asm_out = tmp_root / f"{base}.s"
    rcc_argv = [
        str(rcc),
        *cfg.default_rcc_flags,
        *per_test,
        rcc_src_arg(cfg.root, src),
        "-o",
        str(asm_out),
    ]
    r = run_capture(rcc_argv, cwd=cfg.root / "compiler")
    if r.returncode != 0:
        return [
            TResult(
                False,
                name,
                "rcc failed:\n" + (r.stderr or r.stdout or ""),
            )
        ]

    s_expect = compiler_tests / f"{base}.s.expect"
    if s_expect.is_file():
        got = asm_out.read_text(encoding="utf-8")
        exp = s_expect.read_text(encoding="utf-8")
        if got != exp:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(exp, got, str(s_expect), "generated asm"),
                    sub="s.expect",
                )
            )
            return results

    out_expect = compiler_tests / f"{base}.output.expect"
    sim_extra = parse_flags_file(compiler_tests / f"{base}.simflags")
    input_path = compiler_tests / f"{base}.input"
    has_input = input_path.is_file()

    lib = lib_dir(cfg.root)
    crt0_s = cfg.root / "lib" / "crt0.s"

    if not cfg.hsasm_path or not cfg.hsld_path:
        msg = "hsasm+hsld required to link crt0 with rcc output (cabal build exe:hsasm exe:hsld in hstools/)"
        if cfg.skip_unavailable:
            return [TResult(True, name, f"(skipped) {msg}")]
        return [TResult(False, name, msg)]

    asm_txt = asm_out.read_text()
    defs = parse_rcc_defines(asm_txt)
    code_b = defs.get("RCC_CODE_BASE", "0o1000")
    data_opt = defs.get("RCC_DATA_BASE", "0o3000") if ".section data" in asm_txt else None
    stack_t = defs.get("RCC_STACK_TOP", "0o3000")

    bin_path = tmp_root / f"{base}.bin"
    crt0_o = tmp_root / f"{base}.crt0.o"
    user_o = tmp_root / f"{base}.rcc.o"

    ar0 = run_capture(
        hsasm_emit_obj_cmd(
            cfg.hsasm_path,
            crt0_s,
            crt0_o,
            cli_defines=[("RCC_STACK_TOP", stack_t)],
        ),
        cwd=cfg.root,
    )
    if ar0.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsasm (crt0) failed:\n" + (ar0.stderr or ar0.stdout or ""),
                sub="crt0.o",
            )
        ]

    aru = run_capture(
        hsasm_emit_obj_cmd(cfg.hsasm_path, asm_out, user_o, include_dirs=[lib]),
        cwd=cfg.root / "compiler",
    )
    if aru.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsasm (rcc .s) failed:\n" + (aru.stderr or aru.stdout or ""),
                sub="user.o",
            )
        ]

    arl = run_capture(
        hsld_cmd(
            cfg.hsld_path,
            [crt0_o, user_o],
            bin_path,
            code_base=code_b,
            data_base=data_opt,
        ),
        cwd=cfg.root,
    )
    if arl.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsld failed:\n" + (arl.stderr or arl.stdout or ""),
                sub="hsld",
            )
        ]

    for sim_id in cfg.simulators:
        if sim_id == "c" and not cfg.sim2_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "sim2 not found", sub="link/csim"))
            continue
        if sim_id == "hs" and not cfg.rsim_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "rsim not found", sub="link/rsim"))
            continue

        sim_argv: list[str]
        sim_base = sim_runner_base(cfg, defs)
        if sim_id == "py":
            sim_argv = [
                python_exe(),
                str(sim_py_path(cfg.root)),
                *sim_base,
                *sim_extra,
            ]
            if has_input:
                sim_argv.append("--terminal")
            sim_argv.append(str(bin_path))
        elif sim_id == "hs":
            sim_argv = [
                str(cfg.rsim_path),
                *sim_base,
                *sim_extra,
            ]
            if has_input:
                sim_argv.append("--terminal")
            sim_argv.append(str(bin_path))
        else:
            sim_argv = [
                str(cfg.sim2_path),
                *sim_base,
                *sim_extra,
            ]
            if has_input:
                sim_argv.append("--terminal")
            sim_argv.append(str(bin_path))

        sr = run_capture(
            sim_argv,
            cwd=cfg.root / "compiler",
            stdin_path=input_path if has_input else None,
        )
        if sr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"simulator ({sim_id}) exit {sr.returncode}:\n"
                    + (sr.stderr or sr.stdout or ""),
                    sub=f"link/{sim_id}sim",
                )
            )
            continue

        if not out_expect.is_file():
            results.append(
                TResult(True, name, "no .output.expect", sub=f"link/{sim_id}sim")
            )
            continue

        actual = sr.stdout or ""
        expected = out_expect.read_text(encoding="utf-8")
        if actual != expected:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(expected, actual, str(out_expect), "sim stdout"),
                    sub=f"link/{sim_id}sim",
                )
            )
        else:
            results.append(TResult(True, name, sub=f"link/{sim_id}sim"))

    if not results:
        results.append(TResult(True, name, "(all matrix slots skipped)"))
    return results


def collect_io_tests(cfg: RunConfig) -> list[Path]:
    d = cfg.root / "compiler" / "tests" / "io"
    if not d.is_dir():
        return []
    xs = sorted(p for p in d.glob("*.c") if p.is_file())
    if cfg.filter_re:
        xs = [p for p in xs if cfg.filter_re.search(p.stem)]
    return xs


def run_io_terminal_test(cfg: RunConfig, src: Path, tmp_root: Path, gcc_path: Path | None) -> list[TResult]:
    """Golden UART output vs simulator (--terminal) and host gcc. Expect file is never blessed."""
    io_dir = cfg.root / "compiler" / "tests" / "io"
    base = src.stem
    name = f"io:{base}"
    results: list[TResult] = []

    exp_path = io_dir / f"{base}.stdout.expect"
    if not exp_path.is_file():
        return [
            TResult(
                False,
                name,
                f"missing golden {exp_path.name} (manual file; not generated by --bless-output)",
            )
        ]

    expected_txt = exp_path.read_text(encoding="utf-8")

    rcc = cfg.rcc_path
    if not rcc:
        return [
            TResult(False, name, "rcc not found (build with: cd compiler && cabal build exe:rcc)")
        ]

    per_rcc = parse_flags_file(io_dir / f"{base}.rccflags")
    per_sim = parse_flags_file(io_dir / f"{base}.simflags")
    input_path = io_dir / f"{base}.input"
    has_input = input_path.is_file()

    asm_out = tmp_root / f"{base}.s"
    rcc_argv = [
        str(rcc),
        *cfg.default_rcc_flags,
        *IO_RCC_EXTRA_DEFAULT,
        *per_rcc,
        rcc_src_arg(cfg.root, src),
        "-o",
        str(asm_out),
    ]
    rc = run_capture(rcc_argv, cwd=cfg.root / "compiler")
    if rc.returncode != 0:
        return [
            TResult(
                False,
                name,
                "rcc failed:\n" + (rc.stderr or rc.stdout or ""),
            )
        ]

    lib = lib_dir(cfg.root)
    crt0_s = cfg.root / "lib" / "crt0.s"

    if not cfg.hsasm_path or not cfg.hsld_path:
        msg = "hsasm+hsld required (cabal build exe:hsasm exe:hsld in hstools/)"
        if cfg.skip_unavailable:
            return [TResult(True, name, f"(skipped) {msg}")]
        return [TResult(False, name, msg)]

    asm_txt = asm_out.read_text()
    defs = parse_rcc_defines(asm_txt)
    code_b = defs.get("RCC_CODE_BASE", "0o100")
    data_opt = defs.get("RCC_DATA_BASE", "0o6600") if ".section data" in asm_txt else None
    stack_t = defs.get("RCC_STACK_TOP", "0o7770")

    bin_path = tmp_root / f"io-{base}.bin"
    crt0_o = tmp_root / f"io-{base}.crt0.o"
    user_o = tmp_root / f"io-{base}.rcc.o"

    ar0 = run_capture(
        hsasm_emit_obj_cmd(
            cfg.hsasm_path,
            crt0_s,
            crt0_o,
            cli_defines=[("RCC_STACK_TOP", stack_t)],
        ),
        cwd=cfg.root,
    )
    if ar0.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsasm (crt0) failed:\n" + (ar0.stderr or ar0.stdout or ""),
                sub="crt0.o",
            )
        ]

    aru = run_capture(
        hsasm_emit_obj_cmd(cfg.hsasm_path, asm_out, user_o, include_dirs=[lib]),
        cwd=cfg.root / "compiler",
    )
    if aru.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsasm (rcc .s) failed:\n" + (aru.stderr or aru.stdout or ""),
                sub="user.o",
            )
        ]

    arl = run_capture(
        hsld_cmd(
            cfg.hsld_path,
            [crt0_o, user_o],
            bin_path,
            code_base=code_b,
            data_base=data_opt,
        ),
        cwd=cfg.root,
    )
    if arl.returncode != 0:
        return [
            TResult(
                False,
                name,
                "hsld failed:\n" + (arl.stderr or arl.stdout or ""),
                sub="hsld",
            )
        ]

    start_addr = defs.get("RCC_CODE_BASE", "0o100")
    io_sim_base = replace_argv_flag(list(IO_SIM_EXTRA_DEFAULT), "--start", start_addr)

    for sim_id in cfg.simulators:
        if sim_id == "c" and not cfg.sim2_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "sim2 not found", sub="link/csim"))
            continue
        if sim_id == "hs" and not cfg.rsim_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "rsim not found", sub="link/rsim"))
            continue

        sim_argv: list[str]
        if sim_id == "py":
            sim_argv = [
                python_exe(),
                str(sim_py_path(cfg.root)),
                *io_sim_base,
                *per_sim,
                str(bin_path),
            ]
        elif sim_id == "hs":
            sim_argv = [
                str(cfg.rsim_path),
                *io_sim_base,
                *per_sim,
                str(bin_path),
            ]
        else:
            sim_argv = [
                str(cfg.sim2_path),
                *io_sim_base,
                *per_sim,
                str(bin_path),
            ]

        sr = run_capture(
            sim_argv,
            cwd=cfg.root / "compiler",
            stdin_path=input_path if has_input else None,
        )
        if sr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"simulator ({sim_id}) exit {sr.returncode}:\n"
                    + (sr.stderr or sr.stdout or ""),
                    sub=f"link/{sim_id}sim",
                )
            )
            continue

        actual = sr.stdout or ""
        if actual != expected_txt:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(expected_txt, actual, str(exp_path), "sim uart stdout"),
                    sub=f"link/{sim_id}sim",
                )
            )
        else:
            results.append(TResult(True, name, sub=f"link/{sim_id}sim"))

    # Host gcc: same source, same expected UART bytes (stay in 12-bit range).
    if gcc_path is None:
        if cfg.skip_unavailable:
            results.append(
                TResult(True, name, "gcc not found (host check skipped)", sub="host/gcc")
            )
        else:
            results.append(
                TResult(
                    False,
                    name,
                    "gcc not found (required for io suite host comparison)",
                    sub="host/gcc",
                )
            )
    else:
        host_exe = tmp_root / f"io-{base}.host.bin"
        gcc_argv = [
            str(gcc_path),
            "-std=c99",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-DRRISC_IO_TEST_HOST",
            f"-I{io_dir}",
            f"-I{cfg.root / 'lib'}",
            str(src.resolve()),
            "-o",
            str(host_exe),
        ]
        gr = run_capture(gcc_argv, cwd=cfg.root)
        if gr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    "host gcc failed:\n" + (gr.stderr or gr.stdout or ""),
                    sub="host/gcc",
                )
            )
        else:
            hr = run_capture(
                [str(host_exe)],
                cwd=cfg.root / "compiler",
                stdin_path=input_path if has_input else None,
            )
            if hr.returncode != 0:
                results.append(
                    TResult(
                        False,
                        name,
                        f"host binary exit {hr.returncode}:\n"
                        + (hr.stderr or hr.stdout or ""),
                        sub="host/gcc",
                    )
                )
            else:
                got = hr.stdout or ""
                if got != expected_txt:
                    results.append(
                        TResult(
                            False,
                            name,
                            diff_text(expected_txt, got, str(exp_path), "host stdout"),
                            sub="host/gcc",
                        )
                    )
                else:
                    results.append(TResult(True, name, sub="host/gcc"))

    if not results:
        results.append(TResult(True, name, "(all matrix slots skipped)"))
    return results


def bless_rcc_output(cfg: RunConfig) -> int:
    """Rewrite compiler/tests/[0-9]*.output.expect using rcc + hsasm (or asm.py) + Python sim.

    Golden UART expectations live under compiler/tests/io/*.stdout.expect and are maintained by hand.
    """
    rcc = cfg.rcc_path
    if not rcc:
        print("bless-output: rcc not found", file=sys.stderr)
        return 1
    compiler_tests = cfg.root / "compiler" / "tests"
    lib = lib_dir(cfg.root)
    if not cfg.hsasm_path:
        print(
            "bless-output: warning: hsasm not found; using deprecated asm.py. "
            "Build exe:hsasm in hstools/.",
            file=sys.stderr,
        )
    elif not cfg.hsld_path:
        print(
            "bless-output: warning: hsld not found; falling back to flat hsasm/asm.py "
            "(build exe:hsld for crt0 link).",
            file=sys.stderr,
        )
    n_ok = n_fail = n_skip = 0
    with tempfile.TemporaryDirectory(prefix="rrisc-bless-out-") as td:
        tdir = Path(td)
        for src in sorted(compiler_tests.glob("[0-9]*.c")):
            base = src.stem
            if cfg.filter_re and not cfg.filter_re.search(base):
                continue
            dest = compiler_tests / f"{base}.output.expect"
            if not dest.is_file():
                n_skip += 1
                continue
            per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
            asm_out = tdir / f"{base}.s"
            bin_out = tdir / f"{base}.bin"
            rcc_argv = [
                str(rcc),
                *cfg.default_rcc_flags,
                *per_test,
                rcc_src_arg(cfg.root, src),
                "-o",
                str(asm_out),
            ]
            r = run_capture(rcc_argv, cwd=cfg.root / "compiler")
            if r.returncode != 0:
                print(f"bless-output FAIL compile {base}:\n{r.stderr}", file=sys.stderr)
                n_fail += 1
                continue
            asm_txt = asm_out.read_text()
            defs = parse_rcc_defines(asm_txt)
            if cfg.hsasm_path and cfg.hsld_path:
                crt0_s = cfg.root / "lib" / "crt0.s"
                crt0_o = tdir / f"{base}.crt0.o"
                user_o = tdir / f"{base}.rcc.o"
                stack_t = defs.get("RCC_STACK_TOP", "0o3000")
                ar0 = run_capture(
                    hsasm_emit_obj_cmd(
                        cfg.hsasm_path,
                        crt0_s,
                        crt0_o,
                        cli_defines=[("RCC_STACK_TOP", stack_t)],
                    ),
                    cwd=cfg.root,
                )
                aru = run_capture(
                    hsasm_emit_obj_cmd(cfg.hsasm_path, asm_out, user_o, include_dirs=[lib]),
                    cwd=cfg.root / "compiler",
                )
                if ar0.returncode != 0 or aru.returncode != 0:
                    print(
                        f"bless-output FAIL asm obj {base}:\n{ar0.stderr or ''}{aru.stderr or ''}",
                        file=sys.stderr,
                    )
                    n_fail += 1
                    continue
                arl = run_capture(
                    hsld_cmd(
                        cfg.hsld_path,
                        [crt0_o, user_o],
                        bin_out,
                        code_base=defs.get("RCC_CODE_BASE", "0o1000"),
                        data_base=(
                            defs.get("RCC_DATA_BASE", "0o3000")
                            if ".section data" in asm_txt
                            else None
                        ),
                    ),
                    cwd=cfg.root,
                )
                ar = arl
            elif cfg.hsasm_path:
                ar = run_capture(
                    hsasm_cmd(cfg.root, cfg.hsasm_path, src=asm_out, out=bin_out, include_dirs=[lib]),
                    cwd=cfg.root / "compiler",
                )
            else:
                ar = run_capture(
                    py_asm_cmd(cfg.root, src=asm_out, out=bin_out, include_dirs=[lib]),
                    cwd=cfg.root / "compiler",
                )
            if ar.returncode != 0:
                print(f"bless-output FAIL asm {base}:\n{ar.stderr}", file=sys.stderr)
                n_fail += 1
                continue
            sim_extra = parse_flags_file(compiler_tests / f"{base}.simflags")
            input_path = compiler_tests / f"{base}.input"
            has_input = input_path.is_file()
            sim_argv = [
                python_exe(),
                str(sim_py_path(cfg.root)),
                *sim_runner_base(cfg, defs),
                *sim_extra,
            ]
            if has_input:
                sim_argv.append("--terminal")
            sim_argv.append(str(bin_out))
            sr = run_capture(
                sim_argv,
                cwd=cfg.root / "compiler",
                stdin_path=input_path if has_input else None,
            )
            if sr.returncode != 0:
                print(f"bless-output FAIL sim {base}:\n{sr.stderr}", file=sys.stderr)
                n_fail += 1
                continue
            dest.write_text(sr.stdout or "", encoding="utf-8")
            print(f"bless-output: {base}")
            n_ok += 1
    print(f"bless-output: updated {n_ok}, failures {n_fail}, skipped (no file) {n_skip}")
    return 0 if n_fail == 0 else 1


def bless_rcc_asm(cfg: RunConfig) -> int:
    """Rewrite compiler/tests/*.s.expect from current rcc."""
    rcc = cfg.rcc_path
    if not rcc:
        print("bless-asm: rcc not found", file=sys.stderr)
        return 1
    compiler_tests = cfg.root / "compiler" / "tests"
    n_ok = n_fail = 0
    for src in sorted(compiler_tests.glob("[0-9]*.c")):
        base = src.stem
        if cfg.filter_re and not cfg.filter_re.search(base):
            continue
        dest = compiler_tests / f"{base}.s.expect"
        if not dest.is_file():
            continue
        per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
        argv = [
            str(rcc),
            *cfg.default_rcc_flags,
            *per_test,
            rcc_src_arg(cfg.root, src),
            "-o",
            str(dest),
        ]
        r = run_capture(argv, cwd=cfg.root / "compiler")
        if r.returncode == 0:
            print(f"bless-asm: {base}")
            n_ok += 1
        else:
            print(f"bless-asm FAIL: {base}\n{r.stderr}", file=sys.stderr)
            n_fail += 1
    print(f"bless-asm: updated {n_ok}, failures {n_fail}")
    return 0 if n_fail == 0 else 1


# --- Flat assembler tests (tests/*.s) --------------------------------------

def run_asm_error_test(cfg: RunConfig, src: Path) -> TResult:
    base = src.stem
    expect = cfg.root / "tests" / f"{base}.err.expect"
    if cfg.hsasm_path:
        r = run_capture([str(cfg.hsasm_path), str(src)], cwd=cfg.root)
    else:
        r = run_capture([python_exe(), str(asm_py_path(cfg.root)), str(src)], cwd=cfg.root)
    if r.returncode == 0:
        return TResult(False, f"asmerr:{base}", "assembler succeeded but should fail")
    if not expect.is_file():
        return TResult(True, f"asmerr:{base}", "(no .err.expect)")
    err = r.stderr or ""
    if not cfg.hsasm_path:
        err = _stderr_without_py_asm_deprecation(err)
    exp = expect.read_text(encoding="utf-8")
    if err != exp:
        return TResult(False, f"asmerr:{base}", diff_text(exp, err, str(expect), "stderr"))
    return TResult(True, f"asmerr:{base}")


def run_asm_success_test(cfg: RunConfig, src: Path, tmp_root: Path) -> list[TResult]:
    base = src.stem
    name = f"asm:{base}"
    results: list[TResult] = []
    test_dir = cfg.root / "tests"
    bin_expect = test_dir / f"{base}.bin.expect"
    out_expect = test_dir / f"{base}.output.expect"
    flags = parse_flags_file(test_dir / f"{base}.flags")

    sim_base_py = ["--summary", "--maxcycle", str(cfg.asm_test_maxcycle)]
    sim_base_c = ["--summary", "--maxcycle", str(cfg.asm_test_maxcycle)]

    bins: dict[str, Path] = {}

    for asm_id in cfg.assemblers:
        if asm_id == "hs" and not cfg.hsasm_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "hsasm not found", sub="hsasm"))
            continue
        bin_path = tmp_root / f"{base}.{asm_id}.bin"
        if asm_id == "py":
            ar = run_capture(
                py_asm_cmd(cfg.root, src=src, out=bin_path, include_dirs=()),
                cwd=cfg.root,
            )
        else:
            ar = run_capture(
                hsasm_cmd(cfg.root, cfg.hsasm_path, src=src, out=bin_path, include_dirs=()),
                cwd=cfg.root,
            )
        if ar.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"assembler ({asm_id}):\n" + (ar.stderr or ar.stdout or ""),
                    sub=f"{asm_id}asm",
                )
            )
            return results
        bins[asm_id] = bin_path

        if bin_expect.is_file():
            got = bin_path.read_bytes()
            exp = bin_expect.read_bytes()
            if got != exp:
                results.append(
                    TResult(
                        False,
                        name,
                        f"binary mismatch ({asm_id}) vs {bin_expect.name}",
                        sub=f"{asm_id}asm/bin.expect",
                    )
                )
                return results

    if not bins:
        return [TResult(False, name, "no assemblers ran")]

    # Cross-check: py vs hs binaries must match when both ran
    if "py" in bins and "hs" in bins:
        if bins["py"].read_bytes() != bins["hs"].read_bytes():
            results.append(
                TResult(False, name, "pyasm and hsasm produced different .bin", sub="bin-compare")
            )
            return results

    primary_bin = next(iter(bins.values()))

    for sim_id in cfg.simulators:
        if sim_id == "c" and not cfg.sim2_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "sim2 not found", sub=f"*/csim"))
            continue
        if sim_id == "hs" and not cfg.rsim_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "rsim not found", sub=f"*/rsim"))
            continue

        if sim_id == "py":
            sim_argv = [python_exe(), str(sim_py_path(cfg.root)), *sim_base_py, *flags, str(primary_bin)]
        elif sim_id == "hs":
            sim_argv = [str(cfg.rsim_path), *sim_base_py, *flags, str(primary_bin)]
        else:
            sim_argv = [str(cfg.sim2_path), *sim_base_c, *flags, str(primary_bin)]

        sr = run_capture(sim_argv, cwd=cfg.root)
        if sr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"sim ({sim_id}) exit {sr.returncode}:\n" + (sr.stderr or sr.stdout or ""),
                    sub=f"*/{sim_id}sim",
                )
            )
            continue

        if not out_expect.is_file():
            results.append(TResult(True, name, "no .output.expect", sub=f"*/{sim_id}sim"))
            continue

        actual = sr.stdout or ""
        expected = out_expect.read_text(encoding="utf-8")
        if actual != expected:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(expected, actual, str(out_expect), "sim stdout"),
                    sub=f"*/{sim_id}sim",
                )
            )
        else:
            results.append(TResult(True, name, sub=f"*/{sim_id}sim"))

    if not any(r.sub.endswith("sim") and r.ok for r in results if r.sub):
        if not results:
            results.append(TResult(True, name))
    return results


# --- Examples --------------------------------------------------------------

def run_example_test(cfg: RunConfig, src: Path, tmp_root: Path) -> list[TResult]:
    base = src.stem
    name = f"example:{base}"
    results: list[TResult] = []
    bin_path = tmp_root / f"{base}.bin"
    lib = lib_dir(cfg.root)
    # Optional fixture: examples/<base>.input (or examples/float/<base>.input)
    # is fed to the simulator's stdin under --terminal so RX-driven demos halt.
    input_path = src.with_suffix(".input")
    has_input = input_path.is_file()

    tried: list[str] = []
    for asm_id in cfg.assemblers:
        if asm_id == "hs" and not cfg.hsasm_path:
            if cfg.skip_unavailable:
                continue
            tried.append("hs: (hsasm missing)")
            continue
        if asm_id == "py":
            ar = run_capture(
                py_asm_cmd(cfg.root, src=src, out=bin_path, include_dirs=[lib]),
                cwd=cfg.root,
            )
        else:
            ar = run_capture(
                hsasm_cmd(cfg.root, cfg.hsasm_path, src=src, out=bin_path, include_dirs=[lib]),
                cwd=cfg.root,
            )
        if ar.returncode != 0:
            tried.append(f"{asm_id}: {ar.stderr or ar.stdout or ''}".strip())
            continue
        break
    else:
        return [
            TResult(
                False,
                name,
                "no assembler succeeded:\n" + "\n".join(tried),
            )
        ]

    maxc = str(cfg.asm_test_maxcycle)
    for sim_id in cfg.simulators:
        if sim_id == "c" and not cfg.sim2_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "sim2 not found", sub=f"{sim_id}sim"))
            continue
        if sim_id == "hs" and not cfg.rsim_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "rsim not found", sub=f"{sim_id}sim"))
            continue
        if sim_id == "py":
            argv = [
                python_exe(),
                str(sim_py_path(cfg.root)),
                "--terminal",
                "--summary",
                "--start",
                "0o1000",
                "--maxcycle",
                maxc,
                str(bin_path),
            ]
        elif sim_id == "hs":
            argv = [
                str(cfg.rsim_path),
                "--terminal",
                "--summary",
                "--start",
                "0o1000",
                "--maxcycle",
                maxc,
                str(bin_path),
            ]
        else:
            argv = [
                str(cfg.sim2_path),
                "--terminal",
                "--summary",
                "--start",
                "0o1000",
                "--maxcycle",
                maxc,
                str(bin_path),
            ]
        sr = run_capture(
            argv,
            cwd=cfg.root,
            stdin_path=input_path if has_input else None,
        )
        if sr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"sim ({sim_id}):\n" + (sr.stderr or sr.stdout or ""),
                    sub=f"{sim_id}sim",
                )
            )
        else:
            results.append(TResult(True, name, sub=f"{sim_id}sim"))

    if not results:
        results.append(TResult(True, name, "(skipped)"))
    return results


# --- orchestration ---------------------------------------------------------

def collect_rcc_tests(cfg: RunConfig) -> tuple[list[Path], list[Path]]:
    cdir = cfg.root / "compiler" / "tests"
    err_tests = sorted(cdir.glob("err-*.c"))
    ok_tests = sorted(cdir.glob("[0-9]*.c"))
    if cfg.filter_re:
        err_tests = [p for p in err_tests if cfg.filter_re.search(p.stem)]
        ok_tests = [p for p in ok_tests if cfg.filter_re.search(p.stem)]
    return err_tests, ok_tests


def collect_asm_tests(cfg: RunConfig) -> tuple[list[Path], list[Path]]:
    tdir = cfg.root / "tests"
    err_tests = sorted(tdir.glob("err-*.s"))
    ok_tests = sorted(tdir.glob("[0-9]*.s"))
    if cfg.filter_re:
        err_tests = [p for p in err_tests if cfg.filter_re.search(p.stem)]
        ok_tests = [p for p in ok_tests if cfg.filter_re.search(p.stem)]
    return err_tests, ok_tests


def collect_examples(cfg: RunConfig) -> list[Path]:
    # Top-level examples plus examples/float/*.s float demos.
    top = list((cfg.root / "examples").glob("*.s"))
    sub = list((cfg.root / "examples" / "float").glob("*.s"))
    ex = sorted(top + sub)
    if cfg.filter_re:
        ex = [p for p in ex if cfg.filter_re.search(p.stem)]
    return ex


def run_float_suite(cfg: RunConfig) -> list[TResult]:
    """Drive tests/float/run_float_tests.py as one suite-level check.

    The float harness has its own per-case parallelism and golden-from-Python
    comparison; we just invoke it and surface a single summary check, plus
    one TResult per failing case so they show up in the unified report.
    """
    name = "float"
    driver = cfg.root / "tests" / "float" / "run_float_tests.py"
    if not driver.is_file():
        return [TResult(False, name, f"missing driver {driver}")]
    argv = [python_exe(), str(driver)]
    if cfg.filter_re:
        argv.extend(["--filter", cfg.filter_re.pattern])
    if cfg.verbose:
        argv.append("--verbose")
    r = run_capture(argv, cwd=cfg.root)
    out = (r.stdout or "") + (r.stderr or "")
    if r.returncode == 0:
        return [TResult(True, name, out.strip() if cfg.verbose else "")]
    fails: list[TResult] = []
    cur_name: str | None = None
    cur_lines: list[str] = []
    for line in out.splitlines():
        if line.startswith("[FAIL] "):
            if cur_name:
                fails.append(TResult(False, f"float:{cur_name}", "\n".join(cur_lines)))
            cur_name = line[len("[FAIL] "):].strip()
            cur_lines = []
        elif cur_name and line.startswith("  "):
            cur_lines.append(line)
    if cur_name:
        fails.append(TResult(False, f"float:{cur_name}", "\n".join(cur_lines)))
    if not fails:
        fails.append(TResult(False, name, out.strip()))
    return fails


def main() -> int:
    ap = argparse.ArgumentParser(description="RRISC unified test runner")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--filter", metavar="REGEX", help="only tests whose stem matches")
    ap.add_argument("--bless-asm", action="store_true", help="rewrite compiler/tests/*.s.expect")
    ap.add_argument(
        "--bless-output",
        action="store_true",
        help="rewrite compiler/tests/[0-9]*.output.expect only (never touches compiler/tests/io/*.stdout.expect)",
    )
    ap.add_argument("--skip-unavailable", action="store_true", help="skip hsasm/rsim/sim2 if missing")
    ap.add_argument("--keep", action="store_true", help="keep temp dirs (print path)")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--rcc", metavar="PATH", help="rcc executable")
    ap.add_argument("--hsasm", metavar="PATH", help="Haskell assembler (hsasm/ras)")
    ap.add_argument("--hsld", metavar="PATH", help="Haskell linker (hsld)")
    ap.add_argument("--rsim", metavar="PATH", help="Haskell simulator (rsim)")
    ap.add_argument("--sim2", metavar="PATH", help="C simulator binary")
    ap.add_argument(
        "--assemblers",
        default="hs",
        help="comma list: hs (default), py (deprecated asm.py)",
    )
    ap.add_argument(
        "--also-rsim",
        action="store_true",
        help="append hs (rsim) to --simulators if missing (redundant with default py,c,hs)",
    )
    ap.add_argument(
        "--simulators",
        default="py,c,hs",
        help="comma list: py, c, hs (default py,c,hs)",
    )
    ap.add_argument(
        "--no-optimize",
        action="store_true",
        help="omit --optimize from default rcc flags",
    )
    ap.add_argument(
        "--only",
        metavar="SUITE,...",
        default="rcc,asm,examples",
        help="comma-separated suites: rcc, asm, examples, io, float (default: rcc,asm,examples)",
    )
    args = ap.parse_args()

    only_parts = {x.strip() for x in args.only.split(",") if x.strip()}
    for p in only_parts:
        if p not in ("rcc", "asm", "examples", "io", "float"):
            print(f"unknown suite in --only: {p!r}", file=sys.stderr)
            return 2
    want_rcc = "rcc" in only_parts
    want_asm = "asm" in only_parts
    want_ex = "examples" in only_parts
    want_io = "io" in only_parts
    want_float = "float" in only_parts

    root = repo_root()
    filt = re.compile(args.filter) if args.filter else None

    assemblers = tuple(x.strip() for x in args.assemblers.split(",") if x.strip())
    simulators = tuple(x.strip() for x in args.simulators.split(",") if x.strip())
    if args.also_rsim and "hs" not in simulators:
        simulators = simulators + ("hs",)
    for a in assemblers:
        if a not in ("py", "hs"):
            print(f"unknown assembler {a!r}", file=sys.stderr)
            return 2
    if "py" in assemblers:
        print(PY_ASM_IN_MATRIX_DEPRECATION, file=sys.stderr)
    for s in simulators:
        if s not in ("py", "c", "hs"):
            print(f"unknown simulator {s!r}", file=sys.stderr)
            return 2

    rcc_path = resolve_rcc(root, args.rcc)
    hsasm_path = resolve_hsasm(root, args.hsasm)
    hsld_path = resolve_hsld(root, getattr(args, "hsld", None))
    rsim_path = resolve_rsim(root, args.rsim)
    sim2_path = resolve_sim2(root, args.sim2)
    gcc_path = resolve_gcc()

    default_rcc = [] if args.no_optimize else ["--optimize"]

    cfg = RunConfig(
        root=root,
        jobs=max(1, args.jobs),
        filter_re=filt,
        assemblers=assemblers,  # type: ignore[arg-type]
        simulators=simulators,  # type: ignore[arg-type]
        skip_unavailable=args.skip_unavailable,
        verbose=args.verbose,
        keep_temps=args.keep,
        rcc_path=rcc_path,
        hsasm_path=hsasm_path,
        hsld_path=hsld_path,
        sim2_path=sim2_path,
        rsim_path=rsim_path,
        default_rcc_flags=default_rcc,
    )

    if args.bless_asm:
        return bless_rcc_asm(cfg)
    if args.bless_output:
        return bless_rcc_output(cfg)

    if not args.skip_unavailable:
        missing = []
        if (want_rcc or want_io) and not hsld_path:
            missing.append("hsld (cabal build exe:hsld in hstools/)")
        if "hs" in assemblers and not hsasm_path:
            missing.append("hsasm (make ras, or cabal build exe:hsasm in hstools/)")
        if "hs" in simulators and not rsim_path:
            missing.append("rsim (make rsim, or cabal build exe:rsim in hstools/)")
        if "c" in simulators and not sim2_path:
            missing.append("sim2 (make sim2)")
        if missing:
            print("Missing tools (use --skip-unavailable to skip):\n  " + "\n  ".join(missing), file=sys.stderr)
            return 2

    all_results: list[TResult] = []

    tmpdir_ctx = tempfile.TemporaryDirectory(prefix="rrisc-tests-")
    if cfg.keep_temps:
        tmp_root = Path(tempfile.mkdtemp(prefix="rrisc-tests-"))
        print(f"keep: temp root {tmp_root}", file=sys.stderr)
    else:
        tmp_root = Path(tmpdir_ctx.__enter__())

    try:
        # RCC error tests (sequential, fast)
        if want_rcc:
            err_c, ok_c = collect_rcc_tests(cfg)
            if cfg.verbose:
                print(
                    f"RCC: {len(err_c)} error tests, {len(ok_c)} success tests (jobs={cfg.jobs})",
                    flush=True,
                )
            for p in err_c:
                res = run_rcc_error_test(cfg, p)
                all_results.append(res)
                emit_verbose(cfg, [res])

            def _rcc_job(p: Path) -> list[TResult]:
                t = Path(tempfile.mkdtemp(dir=tmp_root))
                return run_rcc_success_test(cfg, p, t)

            if ok_c:
                with ThreadPoolExecutor(max_workers=cfg.jobs) as ex:
                    futs = {ex.submit(_rcc_job, p): p for p in ok_c}
                    for fut in as_completed(futs):
                        batch = fut.result()
                        all_results.extend(batch)
                        emit_verbose(cfg, batch)

        # UART golden tests (manual .stdout.expect; host gcc cross-check)
        if want_io:
            io_list = collect_io_tests(cfg)
            if cfg.verbose:
                print(
                    f"IO UART tests: {len(io_list)} programs (jobs={cfg.jobs})",
                    flush=True,
                )

            def _io_job(p: Path) -> list[TResult]:
                t = Path(tempfile.mkdtemp(dir=tmp_root))
                return run_io_terminal_test(cfg, p, t, gcc_path)

            if io_list:
                with ThreadPoolExecutor(max_workers=cfg.jobs) as ex:
                    futs = {ex.submit(_io_job, p): p for p in io_list}
                    for fut in as_completed(futs):
                        batch = fut.result()
                        all_results.extend(batch)
                        emit_verbose(cfg, batch)

        # asm tests
        if want_asm:
            err_s, ok_s = collect_asm_tests(cfg)
            if cfg.verbose:
                print(
                    f"Assembler tests: {len(err_s)} error, {len(ok_s)} success (jobs={cfg.jobs})",
                    flush=True,
                )
            for p in err_s:
                res = run_asm_error_test(cfg, p)
                all_results.append(res)
                emit_verbose(cfg, [res])

            def _asm_job(p: Path) -> list[TResult]:
                t = Path(tempfile.mkdtemp(dir=tmp_root))
                return run_asm_success_test(cfg, p, t)

            if ok_s:
                with ThreadPoolExecutor(max_workers=cfg.jobs) as ex:
                    futs = {ex.submit(_asm_job, p): p for p in ok_s}
                    for fut in as_completed(futs):
                        batch = fut.result()
                        all_results.extend(batch)
                        emit_verbose(cfg, batch)

        # float runtime regression
        if want_float:
            float_results = run_float_suite(cfg)
            all_results.extend(float_results)
            emit_verbose(cfg, float_results)

        # examples
        if want_ex:
            examples = collect_examples(cfg)
            if cfg.verbose and examples:
                print(f"Examples: {len(examples)} files (jobs={cfg.jobs})", flush=True)

            def _ex_job(p: Path) -> list[TResult]:
                t = Path(tempfile.mkdtemp(dir=tmp_root))
                return run_example_test(cfg, p, t)

            if examples:
                with ThreadPoolExecutor(max_workers=cfg.jobs) as ex:
                    futs = {ex.submit(_ex_job, p): p for p in examples}
                    for fut in as_completed(futs):
                        batch = fut.result()
                        all_results.extend(batch)
                        emit_verbose(cfg, batch)

    finally:
        if not cfg.keep_temps:
            tmpdir_ctx.__exit__(None, None, None)

    failed = [r for r in all_results if not r.ok]
    skipped_note = [r for r in all_results if r.ok and "skipped" in r.detail.lower()]

    # stable sort for summary / failure list order
    all_results.sort(key=lambda r: r.name)

    n_fail = len(failed)
    n_ok = len(all_results) - n_fail
    print(f"Results: {n_ok} ok, {n_fail} failed (total checks {len(all_results)})")
    if skipped_note and not cfg.verbose:
        print(f"({len(skipped_note)} checks with skip/note)")

    if n_fail:
        print("\nFailures:", file=sys.stderr)
        for r in failed:
            sub = f" [{r.sub}]" if r.sub else ""
            print(f"  {r.name}{sub}", file=sys.stderr)
            if r.detail:
                print(r.detail, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
