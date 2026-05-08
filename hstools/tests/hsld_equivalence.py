#!/usr/bin/env python3
"""
hsld equivalence check (step 2 of the toolchain refactor).

For every `.s` under tests/ and examples/:
  hsasm src.s --emit-obj  -> src.bin (golden), src.o
  hsld  src.o            -> src.linked.bin
  diff src.bin src.linked.bin   (must be byte-identical)
"""

from __future__ import annotations

import filecmp
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
BIN_BASE = (
    REPO
    / "hstools"
    / "dist-newstyle"
    / "build"
    / "x86_64-linux"
    / "ghc-9.6.7"
    / "hstools-0.1.0.0"
    / "x"
)
HSASM = BIN_BASE / "hsasm" / "build" / "hsasm" / "hsasm"
HSLD = BIN_BASE / "hsld" / "build" / "hsld" / "hsld"


def equivalence(src: Path, tmp: Path, include_dirs: list[Path]) -> tuple[bool, str]:
    bin_path = tmp / (src.stem + ".bin")
    obj_path = tmp / (src.stem + ".o")
    linked_path = tmp / (src.stem + ".linked.bin")

    cmd = [
        str(HSASM),
        str(src),
        "-o", str(bin_path),
        "--emit-obj",
        "--obj-out", str(obj_path),
    ]
    for d in include_dirs:
        cmd += ["-I", str(d)]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        return False, f"hsasm failed: {res.stderr.strip()}"

    res = subprocess.run(
        [str(HSLD), str(obj_path), "-o", str(linked_path)],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        return False, f"hsld failed: {res.stderr.strip()}"

    if not filecmp.cmp(bin_path, linked_path, shallow=False):
        a = bin_path.read_bytes()
        b = linked_path.read_bytes()
        diffs = []
        n = max(len(a), len(b))
        for i in range(n):
            ax = a[i] if i < len(a) else None
            bx = b[i] if i < len(b) else None
            if ax != bx:
                diffs.append(f"  byte {i}: hsasm={ax} hsld={bx}")
                if len(diffs) >= 8:
                    break
        return False, f"binary mismatch:\n" + "\n".join(diffs)
    return True, ""


def main() -> int:
    tmp = Path("/tmp/rrisc-hsld-equivalence")
    tmp.mkdir(exist_ok=True)
    sources: list[tuple[Path, list[Path]]] = []

    lib = REPO / "lib"
    for s in sorted((REPO / "examples").rglob("*.s")):
        sources.append((s, [lib]))
    for s in sorted((REPO / "tests").rglob("*.s")):
        if s.name.startswith("err-"):
            continue
        sources.append((s, [lib]))

    ok = 0
    fail: list[str] = []
    for src, incs in sources:
        passed, msg = equivalence(src, tmp, incs)
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
