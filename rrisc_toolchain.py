#!/usr/bin/env python3
"""Shared path resolution, flags, and argv builders for RRISC tooling (tests, scripts).

Haskell-first: prefer `ras` / `rld` / `rsim` from cabal-built binaries under
`tools/`. The deprecated flat assembler lives in `pytools` (`python3 -m pytools.asm`).
"""

from __future__ import annotations

import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence

# Layout / UART flags for compiler/tests/io/*.c (matches demos/Makefile defaults).
IO_RCC_EXTRA_DEFAULT: tuple[str, ...] = (
    "--code-base",
    "0o100",
    "--data-base",
    "0o6600",
    "--stack-top",
    "0o7770",
    "--preprocessor",
    "cpp -P -I ../lib -I tests/io",
)
IO_SIM_EXTRA_DEFAULT: tuple[str, ...] = (
    "--mem",
    "ram:0:0o7770",
    "--start",
    "0o100",
    "--terminal",
    "--maxcycle",
    "2000000",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parent


def lib_dir(root: Path | None = None) -> Path:
    return (root or repo_root()) / "lib"


def parse_flags_file(path: Path) -> list[str]:
    if not path.is_file():
        return []
    out: list[str] = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out.extend(shlex.split(line))
    return out


def rcc_src_arg(root: Path, src: Path) -> str:
    """Input path for rcc so diagnostics match compiler/tests/*.err.expect (cwd=compiler/)."""
    comp = (root / "compiler").resolve()
    try:
        return str(src.resolve().relative_to(comp))
    except ValueError:
        return str(src)


def which_or_path(p: str | None) -> Path | None:
    if not p:
        return None
    x = Path(p)
    if x.is_file():
        return x.resolve()
    w = shutil.which(p)
    return Path(w).resolve() if w else None


def cabal_list_bin(project_dir: Path, exe: str) -> Path | None:
    try:
        r = subprocess.run(
            ["cabal", "list-bin", exe],
            cwd=project_dir,
            capture_output=True,
            text=True,
            check=False,
        )
        if r.returncode != 0:
            return None
        line = (r.stdout or "").strip().splitlines()[-1].strip()
        p = Path(line)
        return p if p.is_file() else None
    except OSError:
        return None


def _usable_exe(p: Path | None) -> Path | None:
    if not p:
        return None
    try:
        r = p.resolve()
    except OSError:
        return None
    return r if r.is_file() and os.access(r, os.X_OK) else None


def python_exe() -> str:
    """Interpreter for ``pytools.asm`` / ``pytools.sim`` (avoid broken sys.executable in some IDEs)."""
    if _usable_exe(Path(sys.executable)):
        return sys.executable
    w = shutil.which("python3") or shutil.which("python")
    return w or "python3"


def py_asm_argv() -> list[str]:
    """Argv prefix to run the deprecated flat assembler: ``python3 -m pytools.asm``."""
    return [python_exe(), "-m", "pytools.asm"]


def py_sim_argv() -> list[str]:
    """Argv prefix to run the Python simulator: ``python3 -m pytools.sim``."""
    return [python_exe(), "-m", "pytools.sim"]


def resolve_rcc(root: Path, override: str | None) -> Path | None:
    w = _usable_exe(which_or_path(override))
    if w:
        return w
    built = _usable_exe(cabal_list_bin(root / "compiler", "exe:rcc"))
    if built:
        return built
    return _usable_exe(root / "rcc")


def resolve_ras(root: Path, override: str | None) -> Path | None:
    w = _usable_exe(which_or_path(override))
    if w:
        return w
    built = _usable_exe(cabal_list_bin(root / "tools", "exe:ras"))
    if built:
        return built
    return _usable_exe(which_or_path("ras"))


def resolve_rld(root: Path, override: str | None) -> Path | None:
    w = _usable_exe(which_or_path(override))
    if w:
        return w
    built = _usable_exe(cabal_list_bin(root / "tools", "exe:rld"))
    if built:
        return built
    return _usable_exe(which_or_path("rld"))


def resolve_rsim(root: Path, override: str | None) -> Path | None:
    w = _usable_exe(which_or_path(override))
    if w:
        return w
    built = _usable_exe(cabal_list_bin(root / "tools", "exe:rsim"))
    if built:
        return built
    return _usable_exe(root / "rsim")


def resolve_sim2(root: Path, override: str | None) -> Path | None:
    w = _usable_exe(which_or_path(override))
    if w:
        return w
    return _usable_exe(root / "sim2")


def resolve_gcc() -> Path | None:
    w = shutil.which("gcc")
    return Path(w).resolve() if w else None


def py_asm_cmd(
    root: Path,
    *,
    src: Path,
    out: Path,
    include_dirs: Sequence[Path] | None = None,
) -> list[str]:
    argv = [*py_asm_argv()]
    for d in include_dirs or ():
        argv.extend(["-I", str(d)])
    argv.extend([str(src), "-o", str(out)])
    return argv


def ras_cmd(
    root: Path,
    ras: Path,
    *,
    src: Path,
    out: Path,
    include_dirs: Sequence[Path] | None = None,
) -> list[str]:
    argv = [str(ras), str(src), "--format", "bin", "-o", str(out)]
    for d in include_dirs or ():
        argv.extend(["-I", str(d)])
    return argv


def parse_rcc_defines(text: str) -> dict[str, str]:
    """Parse leading `%define RCC_*` lines from rcc-generated assembly."""
    d: dict[str, str] = {}
    for line in text.splitlines():
        t = line.strip()
        if not t.startswith("%define RCC_"):
            continue
        parts = t.split(None, 2)
        if len(parts) >= 3:
            d[parts[1]] = parts[2].strip()
    return d


def ras_emit_obj_cmd(
    ras: Path,
    src: Path,
    obj_out: Path,
    *,
    include_dirs: Sequence[Path] | None = None,
    cli_defines: Sequence[tuple[str, str]] | None = None,
) -> list[str]:
    argv = [str(ras), str(src), "-o", str(obj_out)]
    for d in include_dirs or ():
        argv.extend(["-I", str(d)])
    for k, v in cli_defines or ():
        argv.extend(["-D", f"{k}={v}"])
    return argv


def rld_cmd(
    rld: Path,
    objs: Sequence[Path],
    out_bin: Path,
    *,
    code_base: str,
    data_base: str | None,
) -> list[str]:
    argv = [
        str(rld),
        *[str(o) for o in objs],
        "-o",
        str(out_bin),
        "--code-base",
        code_base,
    ]
    if data_base is not None:
        argv.extend(["--data-base", data_base])
    return argv
