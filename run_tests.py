#!/usr/bin/env python3
"""
Unified RRISC test runner: RCC compiler tests, flat-assembler tests, examples,
optional toolchain (obj round-trip / rld) checks on tools/tests/toolchain/*.s,
and optional lib/librcc.s direct harness (tools/tests/librcc/run_librcc_tests.py).

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
  Optional: --bless-io-host refreshes those goldens from gcc only; still run --only io before commit.

Numbered RCC tests with simulator output goldens use a pair of files (both required if either exists):
  stem.output.expect      — stdout from linked binary built with default optimized rcc (-Os/--optimize)
  stem.output.expect.O0   — stdout from the same program built with -O0

Assembly goldens (optional): either legacy stem.s.expect (matches default -Os asm) or all three of
  stem.s.expect.O0, stem.s.expect.Os, stem.s.expect.O1
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
    lib_dir,
    parse_flags_file,
    parse_rcc_defines,
    py_asm_cmd,
    python_exe,
    ras_cmd,
    ras_emit_obj_cmd,
    repo_root,
    rcc_src_arg,
    resolve_gcc,
    resolve_ras,
    resolve_rcc,
    resolve_rld,
    resolve_rsim,
    resolve_sim2,
    rld_cmd,
    sim_py_path,
)
from toolchain_checks import (
    collect_toolchain_asm_sources,
    verify_obj_roundtrip,
    verify_rld_equivalence,
)

PY_ASM_IN_MATRIX_DEPRECATION = (
    "run_tests: warning: --assemblers py (asm.py) is deprecated; "
    "use ras (default --assemblers hs). Example: cabal build exe:ras && cabal list-bin exe:ras."
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
        elif r.ok and r.detail and r.name in ("librcc", "librcc-summary"):
            # librcc: skipped note or harness summary (driver stdout)
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
    ras_path: Path | None
    rld_path: Path | None
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


# Fallback RCC_* addresses when linking (matches typical rcc output for each suite).
RCC_LINK_FALLBACK_NUMBERED: tuple[str, str, str] = ("0o1000", "0o3000", "0o3000")
RCC_LINK_FALLBACK_IO: tuple[str, str, str] = ("0o100", "0o6600", "0o7770")


def compile_rcc_to_asm(
    cfg: RunConfig,
    src: Path,
    asm_out: Path,
    *,
    extra_rcc_flags: Sequence[str] = (),
) -> tuple[bool, str]:
    """Run rcc with cfg.default_rcc_flags; cwd is compiler/."""
    if not cfg.rcc_path:
        return False, "rcc not found (build with: cd compiler && cabal build exe:rcc)"
    rcc_argv = [
        str(cfg.rcc_path),
        *cfg.default_rcc_flags,
        *extra_rcc_flags,
        rcc_src_arg(cfg.root, src),
        "-o",
        str(asm_out),
    ]
    rc = run_capture(rcc_argv, cwd=cfg.root / "compiler")
    if rc.returncode != 0:
        return False, "rcc failed:\n" + (rc.stderr or rc.stdout or "")
    return True, ""


def rcc_asm_bases(
    asm_txt: str,
    *,
    code_fb: str,
    data_fb: str,
    stack_fb: str,
) -> tuple[str, str | None, str, dict[str, str]]:
    defs = parse_rcc_defines(asm_txt)
    code_b = defs.get("RCC_CODE_BASE", code_fb)
    data_opt = defs.get("RCC_DATA_BASE", data_fb) if ".section data" in asm_txt else None
    stack_t = defs.get("RCC_STACK_TOP", stack_fb)
    return code_b, data_opt, stack_t, defs


def rcc_output_expect_path(compiler_tests: Path, base: str) -> Path:
    return compiler_tests / f"{base}.output.expect"


def rcc_output_expect_o0_path(compiler_tests: Path, base: str) -> Path:
    return compiler_tests / f"{base}.output.expect.O0"


def rcc_asm_expect_paths(compiler_tests: Path, base: str) -> tuple[Path, Path, Path]:
    return (
        compiler_tests / f"{base}.s.expect.O0",
        compiler_tests / f"{base}.s.expect.Os",
        compiler_tests / f"{base}.s.expect.O1",
    )


def _run_rcc_output_variant_sims(
    cfg: RunConfig,
    *,
    name: str,
    base: str,
    tmp_root: Path,
    asm_path: Path,
    out_expect: Path | None,
    variant_label: str,
    sim_extra: list[str],
    input_path: Path | None,
    has_input: bool,
) -> list[TResult]:
    """Link asm_path, run each configured simulator, optionally compare stdout to out_expect."""
    results: list[TResult] = []
    code_fb, data_fb, stack_fb = RCC_LINK_FALLBACK_NUMBERED
    asm_txt = asm_path.read_text()
    code_b, data_opt, stack_t, defs = rcc_asm_bases(
        asm_txt, code_fb=code_fb, data_fb=data_fb, stack_fb=stack_fb
    )

    bin_path = tmp_root / f"{base}.{variant_label}.bin"
    crt0_o = tmp_root / f"{base}.{variant_label}.crt0.o"
    user_o = tmp_root / f"{base}.{variant_label}.rcc.o"

    ok_l, err_l, sub_l = link_rcc_asm_with_crt0(
        cfg,
        asm_path,
        bin_path,
        crt0_o,
        user_o,
        code_base=code_b,
        data_base=data_opt,
        stack_top=stack_t,
    )
    if not ok_l:
        return [TResult(False, name, err_l, sub=f"{variant_label}/{sub_l}")]

    for sim_id in cfg.simulators:
        if sim_id == "c" and not cfg.sim2_path:
            if cfg.skip_unavailable:
                continue
            results.append(
                TResult(False, name, "sim2 not found", sub=f"{variant_label}/link/csim")
            )
            continue
        if sim_id == "hs" and not cfg.rsim_path:
            if cfg.skip_unavailable:
                continue
            results.append(
                TResult(False, name, "rsim not found", sub=f"{variant_label}/link/rsim")
            )
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
        sub = f"{variant_label}/link/{sim_id}sim"
        if sr.returncode != 0:
            results.append(
                TResult(
                    False,
                    name,
                    f"simulator ({sim_id}) exit {sr.returncode}:\n"
                    + (sr.stderr or sr.stdout or ""),
                    sub=sub,
                )
            )
            continue

        if out_expect is None or not out_expect.is_file():
            results.append(TResult(True, name, "no .output.expect", sub=sub))
            continue

        actual = sr.stdout or ""
        expected = out_expect.read_text(encoding="utf-8")
        if actual != expected:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(expected, actual, str(out_expect), "sim stdout"),
                    sub=sub,
                )
            )
        else:
            results.append(TResult(True, name, sub=sub))

    return results


def rcc_asm_embeds_librcc(asm_out: Path) -> bool:
    """True when rcc emitted ``%include \"librcc.s\"`` (integer runtime already in user.o)."""
    return '%include "librcc.s"' in asm_out.read_text(encoding="utf-8")


def link_rcc_asm_with_crt0(
    cfg: RunConfig,
    asm_out: Path,
    bin_path: Path,
    crt0_o: Path,
    user_o: Path,
    *,
    code_base: str,
    data_base: str | None,
    stack_top: str,
) -> tuple[bool, str, str]:
    """Assemble crt0 + one rcc .s and rld-link. On failure, third element is TResult.sub."""
    if not cfg.ras_path or not cfg.rld_path:
        return (
            False,
            "ras+rld required (cabal build exe:ras exe:rld in tools/)",
            "",
        )
    lib = lib_dir(cfg.root)
    crt0_s = cfg.root / "lib" / "crt0.s"
    ar0 = run_capture(
        ras_emit_obj_cmd(
            cfg.ras_path,
            crt0_s,
            crt0_o,
            cli_defines=[("RCC_STACK_TOP", stack_top)],
        ),
        cwd=cfg.root,
    )
    if ar0.returncode != 0:
        return False, "ras (crt0) failed:\n" + (ar0.stderr or ar0.stdout or ""), "crt0.o"
    aru = run_capture(
        ras_emit_obj_cmd(cfg.ras_path, asm_out, user_o, include_dirs=[lib]),
        cwd=cfg.root / "compiler",
    )
    if aru.returncode != 0:
        return False, "ras (rcc .s) failed:\n" + (aru.stderr or aru.stdout or ""), "user.o"
    link_objs: list[Path] = [crt0_o]
    if not rcc_asm_embeds_librcc(asm_out):
        librcc_s = cfg.root / "lib" / "librcc.s"
        librcc_o = user_o.parent / (user_o.stem + "_librcc.o")
        arm = run_capture(
            ras_emit_obj_cmd(cfg.ras_path, librcc_s, librcc_o, include_dirs=[lib]),
            cwd=cfg.root,
        )
        if arm.returncode != 0:
            return False, "ras (librcc.s) failed:\n" + (arm.stderr or arm.stdout or ""), "librcc.o"
        link_objs.append(librcc_o)
    link_objs.append(user_o)
    arl = run_capture(
        rld_cmd(
            cfg.rld_path,
            link_objs,
            bin_path,
            code_base=code_base,
            data_base=data_base,
        ),
        cwd=cfg.root,
    )
    if arl.returncode != 0:
        return False, "rld failed:\n" + (arl.stderr or arl.stdout or ""), "rld"
    return True, "", ""


# --- code size regression (linked .bin words) -------------------------------

SIZE_BASELINE = Path("compiler") / "tests" / "size_baseline.txt"


def tools_tests_asm(root: Path) -> Path:
    """Flat assembler corpus (numbered + err-*.s) and sidecars."""
    return root / "tools" / "tests" / "asm"

# Keep this corpus stable and representative. These are compiler/tests/*.c stems.
SIZE_CORPUS: tuple[str, ...] = (
    "0090-fib",
    "0226-div-4095-2",
    "1605-global-arr-sum",
    "1708-scope-fn-shadow",
    "1802-edge-wrap-mul",
    "1811-edge-mod-by-zero",
    "1900-complex-stack-push-pop",
    "1901-complex-linked-list-sum",
    "1902-complex-isqrt-16",
    "1903-complex-isqrt-100",
    "1904-complex-caesar-sum",
    "1905-complex-popcount-0xFF",
    "1906-complex-selection-sort",
    "1907-complex-gcd-iter",
    "1908-complex-memcpy-check",
    "1909-complex-dot-product",
    "1910-complex-longest-run",
)


def _bin_word_count(p: Path) -> int:
    n = p.stat().st_size
    if n % 2 != 0:
        raise ValueError(f"bin length not multiple of 2: {p} ({n} bytes)")
    return n // 2


def _parse_size_baseline(txt: str) -> dict[str, int]:
    out: dict[str, int] = {}
    for raw in txt.splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 2:
            raise ValueError(f"bad baseline line: {raw!r}")
        stem, words_s = parts
        out[stem] = int(words_s)
    return out


def _format_size_baseline(m: dict[str, int]) -> str:
    lines = [
        "# Linked .bin size baseline (12-bit words; 2 bytes per word)",
        "# Format: <test-stem> <words>",
        "",
    ]
    for k in sorted(m):
        lines.append(f"{k} {m[k]}")
    lines.append("")
    return "\n".join(lines)


def collect_size_tests(cfg: RunConfig) -> list[Path]:
    d = cfg.root / "compiler" / "tests"
    xs: list[Path] = []
    for stem in SIZE_CORPUS:
        p = d / f"{stem}.c"
        if not p.is_file():
            continue
        if cfg.filter_re and not cfg.filter_re.search(stem):
            continue
        xs.append(p)
    return xs


def build_rcc_linked_bin(cfg: RunConfig, src: Path, tmp_root: Path) -> tuple[bool, Path | None, str]:
    """Build a linked .bin (crt0 + rcc output) and return (ok, bin_path, detail)."""
    base = src.stem
    if not cfg.ras_path or not cfg.rld_path:
        return False, None, "ras+rld required (cabal build exe:ras exe:rld in tools/)"

    compiler_tests = cfg.root / "compiler" / "tests"
    per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
    asm_out = tmp_root / f"{base}.s"
    ok, err = compile_rcc_to_asm(cfg, src, asm_out, extra_rcc_flags=per_test)
    if not ok:
        return False, None, err

    code_fb, data_fb, stack_fb = RCC_LINK_FALLBACK_NUMBERED
    asm_txt = asm_out.read_text()
    code_b, data_opt, stack_t, _ = rcc_asm_bases(
        asm_txt, code_fb=code_fb, data_fb=data_fb, stack_fb=stack_fb
    )

    bin_path = tmp_root / f"{base}.bin"
    crt0_o = tmp_root / f"{base}.crt0.o"
    user_o = tmp_root / f"{base}.rcc.o"

    ok_link, err_link, _sub = link_rcc_asm_with_crt0(
        cfg,
        asm_out,
        bin_path,
        crt0_o,
        user_o,
        code_base=code_b,
        data_base=data_opt,
        stack_top=stack_t,
    )
    if not ok_link:
        return False, None, err_link

    return True, bin_path, ""


def run_size_suite(cfg: RunConfig, tmp_root: Path) -> list[TResult]:
    tests = collect_size_tests(cfg)
    if not tests:
        return [TResult(True, "size", "(no size tests selected)")]

    baseline_path = cfg.root / SIZE_BASELINE
    if not baseline_path.is_file():
        return [TResult(False, "size", f"missing baseline: {baseline_path} (run: python3 run_tests.py --bless-size)")]

    baseline = _parse_size_baseline(baseline_path.read_text(encoding="utf-8"))
    results: list[TResult] = []
    for src in tests:
        stem = src.stem
        tdir = Path(tempfile.mkdtemp(dir=tmp_root))
        ok, bin_path, detail = build_rcc_linked_bin(cfg, src, tdir)
        if not ok or not bin_path:
            results.append(TResult(False, f"size:{stem}", detail))
            continue
        got = _bin_word_count(bin_path)
        exp = baseline.get(stem)
        if exp is None:
            results.append(TResult(False, f"size:{stem}", "missing baseline entry (run --bless-size)"))
        elif got > exp:
            results.append(TResult(False, f"size:{stem}", f"code size regressed: {got} words (baseline {exp})"))
        else:
            results.append(TResult(True, f"size:{stem}", f"{got} words" if cfg.verbose else ""))
    return results


def bless_size(cfg: RunConfig) -> int:
    tests = collect_size_tests(cfg)
    if not tests:
        print("bless-size: no tests selected", file=sys.stderr)
        return 1
    if not cfg.rcc_path:
        print("bless-size: rcc not found", file=sys.stderr)
        return 2
    if not cfg.ras_path or not cfg.rld_path:
        print("bless-size: ras+rld required", file=sys.stderr)
        return 2

    out: dict[str, int] = {}
    with tempfile.TemporaryDirectory(prefix="rrisc-bless-size-") as td:
        tmp_root = Path(td)
        for src in tests:
            stem = src.stem
            tdir = Path(tempfile.mkdtemp(dir=tmp_root))
            ok, bin_path, detail = build_rcc_linked_bin(cfg, src, tdir)
            if not ok or not bin_path:
                print(f"bless-size FAIL {stem}:\n{detail}", file=sys.stderr)
                return 1
            out[stem] = _bin_word_count(bin_path)
            print(f"bless-size: {stem} {out[stem]}", flush=True)

    baseline_path = cfg.root / SIZE_BASELINE
    baseline_path.write_text(_format_size_baseline(out), encoding="utf-8")
    print(f"bless-size: wrote {baseline_path}", flush=True)
    return 0


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
    """Compile, link, simulate; compare stdout to paired opt / -O0 goldens when present."""
    base = src.stem
    name = f"rcc:{base}"
    results: list[TResult] = []
    compiler_tests = cfg.root / "compiler" / "tests"
    per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
    out_opt = rcc_output_expect_path(compiler_tests, base)
    out_o0 = rcc_output_expect_o0_path(compiler_tests, base)
    has_opt_golden = out_opt.is_file()
    has_o0_golden = out_o0.is_file()
    if has_opt_golden != has_o0_golden:
        return [
            TResult(
                False,
                name,
                "output goldens must come in pairs: "
                f"both {out_opt.name} and {out_o0.name}, or neither "
                f"(found {out_opt.name if has_opt_golden else out_o0.name} only)",
                sub="goldens",
            )
        ]

    asm_opt = tmp_root / f"{base}.s"
    ok_c, err_c = compile_rcc_to_asm(cfg, src, asm_opt, extra_rcc_flags=per_test)
    if not ok_c:
        return [TResult(False, name, err_c)]

    s_expect_legacy = compiler_tests / f"{base}.s.expect"
    asm_o0_p, asm_os_p, asm_o1_p = rcc_asm_expect_paths(compiler_tests, base)
    n_asm_triple = sum(1 for p in (asm_o0_p, asm_os_p, asm_o1_p) if p.is_file())
    if n_asm_triple not in (0, 3):
        return [
            TResult(
                False,
                name,
                "assembly goldens: need all three "
                f"{asm_o0_p.name}, {asm_os_p.name}, {asm_o1_p.name}, or none "
                f"(found {n_asm_triple} of 3)",
                sub="goldens",
            )
        ]
    if s_expect_legacy.is_file() and n_asm_triple == 3:
        return [
            TResult(
                False,
                name,
                f"remove legacy {s_expect_legacy.name} when using .s.expect.O0/.Os/.O1 triple",
                sub="goldens",
            )
        ]

    if n_asm_triple == 3:
        got_os = asm_opt.read_text(encoding="utf-8")
        exp_os = asm_os_p.read_text(encoding="utf-8")
        if got_os != exp_os:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(exp_os, got_os, str(asm_os_p), "generated asm (-Os)"),
                    sub="s.expect.Os",
                )
            )
            return results
        asm_o0_out = tmp_root / f"{base}.chk.O0.s"
        ok0, err0 = compile_rcc_to_asm(
            cfg, src, asm_o0_out, extra_rcc_flags=("-O0", *per_test)
        )
        if not ok0:
            results.append(TResult(False, name, f"rcc -O0 failed:\n{err0}", sub="s.expect.O0/compile"))
            return results
        exp0 = asm_o0_p.read_text(encoding="utf-8")
        got0 = asm_o0_out.read_text(encoding="utf-8")
        if got0 != exp0:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(exp0, got0, str(asm_o0_p), "generated asm (-O0)"),
                    sub="s.expect.O0",
                )
            )
            return results
        asm_o1_out = tmp_root / f"{base}.chk.O1.s"
        ok1, err1 = compile_rcc_to_asm(
            cfg, src, asm_o1_out, extra_rcc_flags=("-O1", *per_test)
        )
        if not ok1:
            results.append(TResult(False, name, f"rcc -O1 failed:\n{err1}", sub="s.expect.O1/compile"))
            return results
        exp1 = asm_o1_p.read_text(encoding="utf-8")
        got1 = asm_o1_out.read_text(encoding="utf-8")
        if got1 != exp1:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(exp1, got1, str(asm_o1_p), "generated asm (-O1)"),
                    sub="s.expect.O1",
                )
            )
            return results
    elif s_expect_legacy.is_file():
        got = asm_opt.read_text(encoding="utf-8")
        exp = s_expect_legacy.read_text(encoding="utf-8")
        if got != exp:
            results.append(
                TResult(
                    False,
                    name,
                    diff_text(exp, got, str(s_expect_legacy), "generated asm"),
                    sub="s.expect",
                )
            )
            return results

    sim_extra = parse_flags_file(compiler_tests / f"{base}.simflags")
    input_path = compiler_tests / f"{base}.input"
    has_input = input_path.is_file()

    if not cfg.ras_path or not cfg.rld_path:
        msg = "ras+rld required to link crt0 with rcc output (cabal build exe:ras exe:rld in tools/)"
        if cfg.skip_unavailable:
            return [TResult(True, name, f"(skipped) {msg}")]
        return [TResult(False, name, msg)]

    if has_opt_golden and has_o0_golden:
        results.extend(
            _run_rcc_output_variant_sims(
                cfg,
                name=name,
                base=base,
                tmp_root=tmp_root,
                asm_path=asm_opt,
                out_expect=out_opt,
                variant_label="opt",
                sim_extra=sim_extra,
                input_path=input_path,
                has_input=has_input,
            )
        )
        asm_o0 = tmp_root / f"{base}.O0.s"
        ok_o0, err_o0 = compile_rcc_to_asm(
            cfg, src, asm_o0, extra_rcc_flags=("-O0", *per_test)
        )
        if not ok_o0:
            results.append(TResult(False, name, f"rcc -O0 failed:\n{err_o0}", sub="O0/compile"))
            return results
        results.extend(
            _run_rcc_output_variant_sims(
                cfg,
                name=name,
                base=base,
                tmp_root=tmp_root,
                asm_path=asm_o0,
                out_expect=out_o0,
                variant_label="O0",
                sim_extra=sim_extra,
                input_path=input_path,
                has_input=has_input,
            )
        )
    else:
        results.extend(
            _run_rcc_output_variant_sims(
                cfg,
                name=name,
                base=base,
                tmp_root=tmp_root,
                asm_path=asm_opt,
                out_expect=None,
                variant_label="opt",
                sim_extra=sim_extra,
                input_path=input_path,
                has_input=has_input,
            )
        )

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

    per_rcc = parse_flags_file(io_dir / f"{base}.rccflags")
    per_sim = parse_flags_file(io_dir / f"{base}.simflags")
    input_path = io_dir / f"{base}.input"
    has_input = input_path.is_file()

    asm_out = tmp_root / f"{base}.s"
    io_extra = (*IO_RCC_EXTRA_DEFAULT, *per_rcc)
    ok_c, err_c = compile_rcc_to_asm(cfg, src, asm_out, extra_rcc_flags=io_extra)
    if not ok_c:
        return [TResult(False, name, err_c)]

    if not cfg.ras_path or not cfg.rld_path:
        msg = "ras+rld required (cabal build exe:ras exe:rld in tools/)"
        if cfg.skip_unavailable:
            return [TResult(True, name, f"(skipped) {msg}")]
        return [TResult(False, name, msg)]

    code_fb, data_fb, stack_fb = RCC_LINK_FALLBACK_IO
    asm_txt = asm_out.read_text()
    code_b, data_opt, stack_t, defs = rcc_asm_bases(
        asm_txt, code_fb=code_fb, data_fb=data_fb, stack_fb=stack_fb
    )

    bin_path = tmp_root / f"io-{base}.bin"
    crt0_o = tmp_root / f"io-{base}.crt0.o"
    user_o = tmp_root / f"io-{base}.rcc.o"

    ok_l, err_l, sub_l = link_rcc_asm_with_crt0(
        cfg,
        asm_out,
        bin_path,
        crt0_o,
        user_o,
        code_base=code_b,
        data_base=data_opt,
        stack_top=stack_t,
    )
    if not ok_l:
        return [TResult(False, name, err_l, sub=sub_l)]

    start_addr = defs.get("RCC_CODE_BASE", code_fb)
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
    """Rewrite compiler/tests/[0-9]*.output.expect and paired .output.expect.O0 via rcc + rld + py sim.

    Golden UART expectations live under compiler/tests/io/*.stdout.expect and are maintained by hand.
    """
    rcc = cfg.rcc_path
    if not rcc:
        print("bless-output: rcc not found", file=sys.stderr)
        return 1
    compiler_tests = cfg.root / "compiler" / "tests"
    lib = lib_dir(cfg.root)
    if not cfg.ras_path:
        print(
            "bless-output: warning: ras not found; using deprecated asm.py. "
            "Build exe:ras in tools/.",
            file=sys.stderr,
        )
    elif not cfg.rld_path:
        print(
            "bless-output: warning: rld not found; falling back to flat ras/asm.py "
            "(build exe:rld for crt0 link).",
            file=sys.stderr,
        )
    n_ok = n_fail = n_skip = 0
    with tempfile.TemporaryDirectory(prefix="rrisc-bless-out-") as td:
        tdir = Path(td)
        for src in sorted(compiler_tests.glob("[0-9]*.c")):
            base = src.stem
            if cfg.filter_re and not cfg.filter_re.search(base):
                continue
            dest = rcc_output_expect_path(compiler_tests, base)
            dest_o0 = rcc_output_expect_o0_path(compiler_tests, base)
            if not dest.is_file():
                n_skip += 1
                continue
            per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
            sim_extra = parse_flags_file(compiler_tests / f"{base}.simflags")
            input_path = compiler_tests / f"{base}.input"
            has_input = input_path.is_file()

            variant_failed = False
            for label, rcc_xf, out_dest in (
                ("opt", per_test, dest),
                ("O0", ("-O0", *per_test), dest_o0),
            ):
                asm_out = tdir / f"{base}.{label}.s"
                bin_out = tdir / f"{base}.{label}.bin"
                ok_c, err_c = compile_rcc_to_asm(cfg, src, asm_out, extra_rcc_flags=rcc_xf)
                if not ok_c:
                    print(
                        f"bless-output FAIL compile {base} ({label}):\n{err_c}",
                        file=sys.stderr,
                    )
                    n_fail += 1
                    variant_failed = True
                    break
                asm_txt = asm_out.read_text()
                code_fb, data_fb, stack_fb = RCC_LINK_FALLBACK_NUMBERED
                code_b, data_opt, stack_t, defs = rcc_asm_bases(
                    asm_txt, code_fb=code_fb, data_fb=data_fb, stack_fb=stack_fb
                )
                if cfg.ras_path and cfg.rld_path:
                    crt0_o = tdir / f"{base}.{label}.crt0.o"
                    user_o = tdir / f"{base}.{label}.rcc.o"
                    ok_l, err_l, _ = link_rcc_asm_with_crt0(
                        cfg,
                        asm_out,
                        bin_out,
                        crt0_o,
                        user_o,
                        code_base=code_b,
                        data_base=data_opt,
                        stack_top=stack_t,
                    )
                    if not ok_l:
                        print(
                            f"bless-output FAIL asm obj {base} ({label}):\n{err_l}",
                            file=sys.stderr,
                        )
                        n_fail += 1
                        variant_failed = True
                        break
                elif cfg.ras_path:
                    ar = run_capture(
                        ras_cmd(
                            cfg.root, cfg.ras_path, src=asm_out, out=bin_out, include_dirs=[lib]
                        ),
                        cwd=cfg.root / "compiler",
                    )
                    if ar.returncode != 0:
                        print(
                            f"bless-output FAIL asm {base} ({label}):\n{ar.stderr}",
                            file=sys.stderr,
                        )
                        n_fail += 1
                        variant_failed = True
                        break
                else:
                    ar = run_capture(
                        py_asm_cmd(cfg.root, src=asm_out, out=bin_out, include_dirs=[lib]),
                        cwd=cfg.root / "compiler",
                    )
                    if ar.returncode != 0:
                        print(
                            f"bless-output FAIL asm {base} ({label}):\n{ar.stderr}",
                            file=sys.stderr,
                        )
                        n_fail += 1
                        variant_failed = True
                        break
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
                    print(
                        f"bless-output FAIL sim {base} ({label}):\n{sr.stderr}",
                        file=sys.stderr,
                    )
                    n_fail += 1
                    variant_failed = True
                    break
                out_dest.write_text(sr.stdout or "", encoding="utf-8")
            if variant_failed:
                continue
            print(f"bless-output: {base} (opt + O0)")
            n_ok += 1
    print(f"bless-output: updated {n_ok}, failures {n_fail}, skipped (no file) {n_skip}")
    return 0 if n_fail == 0 else 1


def bless_io_host(cfg: RunConfig) -> int:
    """Rewrite io/*.stdout.expect using host gcc + the same flags as run_io_terminal_test."""
    io_dir = cfg.root / "compiler" / "tests" / "io"
    gcc = resolve_gcc()
    if gcc is None:
        print("bless-io-host: gcc not found on PATH", file=sys.stderr)
        return 2
    print(
        "bless-io-host: goldens from host gcc only — run `python3 run_tests.py --only io` "
        "with simulators before commit.",
        file=sys.stderr,
    )
    tests = collect_io_tests(cfg)
    if not tests:
        print("bless-io-host: no tests selected", file=sys.stderr)
        return 1
    n_ok = 0
    with tempfile.TemporaryDirectory(prefix="rrisc-bless-io-host-") as td:
        tmp_root = Path(td)
        for src in tests:
            base = src.stem
            dest = io_dir / f"{base}.stdout.expect"
            if not dest.is_file():
                print(f"bless-io-host: skip {base} (no {dest.name})", file=sys.stderr)
                continue
            input_path = io_dir / f"{base}.input"
            has_input = input_path.is_file()
            host_exe = tmp_root / f"io-{base}.host.bin"
            gcc_argv = [
                str(gcc),
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
                print(f"bless-io-host FAIL compile {base}:\n{gr.stderr or gr.stdout}", file=sys.stderr)
                return 1
            hr = run_capture(
                [str(host_exe)],
                cwd=cfg.root / "compiler",
                stdin_path=input_path if has_input else None,
            )
            if hr.returncode != 0:
                print(
                    f"bless-io-host FAIL run {base}:\n{hr.stderr or hr.stdout}",
                    file=sys.stderr,
                )
                return 1
            dest.write_text(hr.stdout or "", encoding="utf-8")
            print(f"bless-io-host: {base}", flush=True)
            n_ok += 1
    print(f"bless-io-host: updated {n_ok} file(s)", flush=True)
    return 0


def bless_rcc_asm(cfg: RunConfig) -> int:
    """Rewrite compiler/tests assembly goldens: .s.expect.O0, .Os, .O1 (and drop legacy .s.expect)."""
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
        legacy = compiler_tests / f"{base}.s.expect"
        p0, ps, p1 = rcc_asm_expect_paths(compiler_tests, base)
        n_triple = sum(1 for p in (p0, ps, p1) if p.is_file())
        if n_triple in (1, 2):
            print(
                f"bless-asm: skip {base} (incomplete triple: {n_triple}/3 of "
                f"{p0.name}, {ps.name}, {p1.name})",
                file=sys.stderr,
            )
            n_fail += 1
            continue
        if not legacy.is_file() and n_triple == 0:
            continue
        per_test = parse_flags_file(compiler_tests / f"{base}.rccflags")
        src_arg = rcc_src_arg(cfg.root, src)
        ok_this = True
        for flag, dest in (("-O0", p0), ("-Os", ps), ("-O1", p1)):
            argv = [str(rcc), flag, *per_test, src_arg, "-o", str(dest)]
            r = run_capture(argv, cwd=cfg.root / "compiler")
            if r.returncode != 0:
                print(f"bless-asm FAIL: {base} ({flag})\n{r.stderr}", file=sys.stderr)
                ok_this = False
                break
        if not ok_this:
            n_fail += 1
            continue
        if legacy.is_file():
            legacy.unlink()
        print(f"bless-asm: {base}", flush=True)
        n_ok += 1
    print(f"bless-asm: updated {n_ok}, failures {n_fail}")
    return 0 if n_fail == 0 else 1


# --- Flat assembler tests (tools/tests/asm/*.s) ---------------------------

def run_asm_error_test(cfg: RunConfig, src: Path) -> TResult:
    base = src.stem
    expect = tools_tests_asm(cfg.root) / f"{base}.err.expect"
    if cfg.ras_path:
        with tempfile.TemporaryDirectory(prefix="rrisc-asmerr-") as td:
            out_bin = Path(td) / "out.bin"
            r = run_capture(
                [
                    str(cfg.ras_path),
                    str(src),
                    "--format",
                    "bin",
                    "-o",
                    str(out_bin),
                ],
                cwd=cfg.root,
            )
    else:
        r = run_capture([python_exe(), str(asm_py_path(cfg.root)), str(src)], cwd=cfg.root)
    if r.returncode == 0:
        return TResult(False, f"asmerr:{base}", "assembler succeeded but should fail")
    if not expect.is_file():
        return TResult(True, f"asmerr:{base}", "(no .err.expect)")
    err = r.stderr or ""
    if not cfg.ras_path:
        err = _stderr_without_py_asm_deprecation(err)
    exp = expect.read_text(encoding="utf-8")
    if err != exp:
        return TResult(False, f"asmerr:{base}", diff_text(exp, err, str(expect), "stderr"))
    return TResult(True, f"asmerr:{base}")


def run_asm_success_test(cfg: RunConfig, src: Path, tmp_root: Path) -> list[TResult]:
    base = src.stem
    name = f"asm:{base}"
    results: list[TResult] = []
    test_dir = tools_tests_asm(cfg.root)
    bin_expect = test_dir / f"{base}.bin.expect"
    out_expect = test_dir / f"{base}.output.expect"
    flags = parse_flags_file(test_dir / f"{base}.flags")

    sim_base_py = ["--summary", "--maxcycle", str(cfg.asm_test_maxcycle)]
    sim_base_c = ["--summary", "--maxcycle", str(cfg.asm_test_maxcycle)]

    bins: dict[str, Path] = {}

    for asm_id in cfg.assemblers:
        if asm_id == "hs" and not cfg.ras_path:
            if cfg.skip_unavailable:
                continue
            results.append(TResult(False, name, "ras not found", sub="ras"))
            continue
        bin_path = tmp_root / f"{base}.{asm_id}.bin"
        if asm_id == "py":
            ar = run_capture(
                py_asm_cmd(cfg.root, src=src, out=bin_path, include_dirs=()),
                cwd=cfg.root,
            )
        else:
            ar = run_capture(
                ras_cmd(cfg.root, cfg.ras_path, src=src, out=bin_path, include_dirs=()),
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
                TResult(False, name, "pyasm and ras produced different .bin", sub="bin-compare")
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
        if asm_id == "hs" and not cfg.ras_path:
            if cfg.skip_unavailable:
                continue
            tried.append("hs: (ras missing)")
            continue
        if asm_id == "py":
            ar = run_capture(
                py_asm_cmd(cfg.root, src=src, out=bin_path, include_dirs=[lib]),
                cwd=cfg.root,
            )
        else:
            ar = run_capture(
                ras_cmd(cfg.root, cfg.ras_path, src=src, out=bin_path, include_dirs=[lib]),
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
    tdir = tools_tests_asm(cfg.root)
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


def run_toolchain_suite(cfg: RunConfig, tmp_root: Path) -> list[TResult]:
    """Obj round-trip + rld single-object equivalence for ``tools/tests/toolchain/*.s``."""
    if not cfg.ras_path or not cfg.rld_path:
        msg = "ras+rld required (cabal build exe:ras exe:rld in tools/)"
        if cfg.skip_unavailable:
            return [TResult(True, "toolchain", f"(skipped) {msg}")]
        return [TResult(False, "toolchain", msg)]

    sources = collect_toolchain_asm_sources(cfg.root)
    if cfg.filter_re:
        sources = [(s, i) for s, i in sources if cfg.filter_re.search(s.stem)]
    if not sources:
        return [TResult(True, "toolchain", "no matching .s sources")]

    if cfg.verbose:
        print(f"Toolchain checks: {len(sources)} .s files (jobs={cfg.jobs})", flush=True)

    def _job(item: tuple[Path, list[Path]]) -> list[TResult]:
        src, incs = item
        t = Path(tempfile.mkdtemp(dir=tmp_root))
        rel = str(src.relative_to(cfg.root))
        name_base = f"toolchain:{rel}"
        r1: list[TResult] = []
        ok, det = verify_obj_roundtrip(cfg.ras_path, src, t, incs)
        r1.append(
            TResult(
                ok,
                f"{name_base}:obj-roundtrip",
                det,
                sub="obj-roundtrip",
            )
        )
        ok2, det2 = verify_rld_equivalence(cfg.ras_path, cfg.rld_path, src, t, incs)
        r1.append(
            TResult(
                ok2,
                f"{name_base}:rld",
                det2,
                sub="rld-eq",
            )
        )
        return r1

    out: list[TResult] = []
    if len(sources) == 1:
        out.extend(_job(sources[0]))
    else:
        with ThreadPoolExecutor(max_workers=cfg.jobs) as ex:
            futs = {ex.submit(_job, item): item for item in sources}
            for fut in as_completed(futs):
                out.extend(fut.result())
    return out


def run_librcc_suite(cfg: RunConfig) -> list[TResult]:
    """Drive tools/tests/librcc/run_librcc_tests.py (crt0 + librcc + stub main per case).

    With ``cfg.verbose``, split driver stdout into one ``TResult`` per ``PASS`` line
    plus a final summary row so ``emit_verbose`` prints every case (not only ``Results: 1``).
    """
    driver = cfg.root / "tools" / "tests" / "librcc" / "run_librcc_tests.py"
    if not driver.is_file():
        return [TResult(False, "librcc", f"missing driver {driver}")]
    if not cfg.ras_path or not cfg.rld_path:
        msg = "ras+rld required (librcc suite)"
        if cfg.skip_unavailable:
            return [TResult(True, "librcc", f"(skipped) {msg}")]
        return [TResult(False, "librcc", msg)]

    argv = [
        python_exe(),
        str(driver),
        "--ras",
        str(cfg.ras_path),
        "--rld",
        str(cfg.rld_path),
    ]
    if cfg.filter_re:
        argv.extend(["--filter", cfg.filter_re.pattern])
    if cfg.verbose:
        argv.append("--verbose")

    r = run_capture(argv, cwd=cfg.root)
    out = r.stdout or ""
    if r.returncode == 0:
        if cfg.verbose:
            results: list[TResult] = []
            summary_line = ""
            for line in out.splitlines():
                s = line.strip()
                if s.startswith("PASS "):
                    results.append(TResult(True, f"librcc:{s[5:].strip()}", ""))
                elif s.startswith("librcc-tests:"):
                    summary_line = s
            if summary_line:
                results.append(TResult(True, "librcc-summary", summary_line))
            if results:
                return results
            tail = out.strip().splitlines()
            return [TResult(True, "librcc", tail[-1] if tail else "ok")]
        tail = out.strip().splitlines()
        summary = tail[-1] if tail else "ok"
        return [TResult(True, "librcc", "")]
    return [TResult(False, "librcc", (r.stderr or "") + out)]


def run_float_suite(cfg: RunConfig) -> list[TResult]:
    """Drive tools/tests/float/run_float_tests.py as one suite-level check.

    The float harness has its own per-case parallelism and golden-from-Python
    comparison; we just invoke it and surface a single summary check, plus
    one TResult per failing case so they show up in the unified report.
    """
    name = "float"
    driver = cfg.root / "tools" / "tests" / "float" / "run_float_tests.py"
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


def run_float_fuzz_suite(cfg: RunConfig) -> list[TResult]:
    """Drive tools/tests/float/fuzz_float_routines.py (random asm+sim checks, fixed seed)."""
    name = "float-fuzz"
    driver = cfg.root / "tools" / "tests" / "float" / "fuzz_float_routines.py"
    if not driver.is_file():
        return [TResult(False, name, f"missing driver {driver}")]
    argv = [python_exe(), str(driver), "-n", "100", "--seed", "42"]
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
                fails.append(TResult(False, f"float-fuzz:{cur_name}", "\n".join(cur_lines)))
            cur_name = line[len("[FAIL] "):].strip()
            cur_lines = []
        elif cur_name and line.startswith("  "):
            cur_lines.append(line)
    if cur_name:
        fails.append(TResult(False, f"float-fuzz:{cur_name}", "\n".join(cur_lines)))
    if not fails:
        fails.append(TResult(False, name, out.strip()))
    return fails


def main() -> int:
    ap = argparse.ArgumentParser(description="RRISC unified test runner")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--filter", metavar="REGEX", help="only tests whose stem matches")
    ap.add_argument(
        "--bless-asm",
        action="store_true",
        help="rewrite compiler/tests/*.s.expect.{O0,Os,O1} from rcc (drops legacy .s.expect)",
    )
    ap.add_argument(
        "--bless-size",
        action="store_true",
        help="rewrite compiler/tests/size_baseline.txt",
    )
    ap.add_argument(
        "--bless-output",
        action="store_true",
        help=(
            "rewrite compiler/tests/[0-9]*.output.expect and .output.expect.O0 "
            "(never touches compiler/tests/io/*.stdout.expect)"
        ),
    )
    ap.add_argument(
        "--bless-io-host",
        action="store_true",
        help=(
            "rewrite compiler/tests/io/*.stdout.expect from host gcc only "
            "(still run --only io with simulators before commit)"
        ),
    )
    ap.add_argument("--skip-unavailable", action="store_true", help="skip ras/rsim/sim2 if missing")
    ap.add_argument("--keep", action="store_true", help="keep temp dirs (print path)")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--rcc", metavar="PATH", help="rcc executable")
    ap.add_argument("--ras", metavar="PATH", help="RRISC assembler (ras)")
    ap.add_argument("--rld", metavar="PATH", help="RRISC linker (rld)")
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
        help=(
            "comma-separated suites: rcc, asm, examples, io, float, float-fuzz, "
            "toolchain, size, librcc (default: rcc,asm,examples)"
        ),
    )
    args = ap.parse_args()

    only_parts = {x.strip() for x in args.only.split(",") if x.strip()}
    for p in only_parts:
        if p not in ("rcc", "asm", "examples", "io", "float", "float-fuzz", "toolchain", "size", "librcc"):
            print(f"unknown suite in --only: {p!r}", file=sys.stderr)
            return 2
    want_rcc = "rcc" in only_parts
    want_asm = "asm" in only_parts
    want_ex = "examples" in only_parts
    want_io = "io" in only_parts
    want_float = "float" in only_parts
    want_float_fuzz = "float-fuzz" in only_parts
    want_toolchain = "toolchain" in only_parts
    want_size = "size" in only_parts
    want_librcc = "librcc" in only_parts

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
    ras_path = resolve_ras(root, args.ras)
    rld_path = resolve_rld(root, args.rld)
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
        ras_path=ras_path,
        rld_path=rld_path,
        sim2_path=sim2_path,
        rsim_path=rsim_path,
        default_rcc_flags=default_rcc,
    )

    if args.bless_asm:
        return bless_rcc_asm(cfg)
    if args.bless_output:
        return bless_rcc_output(cfg)
    if args.bless_io_host:
        return bless_io_host(cfg)
    if args.bless_size:
        return bless_size(cfg)

    if not args.skip_unavailable:
        missing = []
        if (want_rcc or want_io or want_toolchain or want_librcc) and not rld_path:
            missing.append("rld (cabal build exe:rld in tools/)")
        if (want_toolchain or want_librcc or "hs" in assemblers) and not ras_path:
            missing.append("ras (cabal build exe:ras in tools/)")
        if "hs" in simulators and not rsim_path:
            missing.append("rsim (cabal build exe:rsim in tools/)")
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

        # float runtime fuzz (random programs vs Python oracle)
        if want_float_fuzz:
            ff_results = run_float_fuzz_suite(cfg)
            all_results.extend(ff_results)
            emit_verbose(cfg, ff_results)

        # lib/librcc.s direct harness (multiply / divide / mod)
        if want_librcc:
            lr_results = run_librcc_suite(cfg)
            all_results.extend(lr_results)
            emit_verbose(cfg, lr_results)

        # linked .bin code size baseline
        if want_size:
            size_results = run_size_suite(cfg, tmp_root)
            all_results.extend(size_results)
            emit_verbose(cfg, size_results)

        # ras .o round-trip + rld flat equivalence (see toolchain_checks.py)
        if want_toolchain:
            tc_results = run_toolchain_suite(cfg, tmp_root)
            all_results.extend(tc_results)
            emit_verbose(cfg, tc_results)

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
