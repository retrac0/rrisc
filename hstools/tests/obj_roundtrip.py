#!/usr/bin/env python3
"""Object-file round-trip check: see toolchain_checks.verify_obj_roundtrip."""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
if str(_REPO) not in sys.path:
    sys.path.insert(0, str(_REPO))

from toolchain_checks import collect_toolchain_asm_sources, verify_obj_roundtrip
from rrisc_toolchain import resolve_hsasm, repo_root


def main() -> int:
    root = repo_root()
    hsasm = resolve_hsasm(root, None)
    if not hsasm:
        print("hsasm not found (build: cabal build exe:hsasm from repo root)", file=sys.stderr)
        return 2
    tmp = Path(tempfile.mkdtemp(prefix="rrisc-obj-roundtrip-"))
    ok_n = 0
    fail: list[str] = []
    for src, incs in collect_toolchain_asm_sources(root):
        passed, msg = verify_obj_roundtrip(hsasm, src, tmp, incs)
        rel = src.relative_to(root)
        if passed:
            ok_n += 1
        else:
            fail.append(f"{rel}\n{msg}")
    if fail:
        print(f"FAILED {len(fail)} of {ok_n + len(fail)}")
        for f in fail:
            print("---")
            print(f)
        return 1
    print(f"OK {ok_n}/{ok_n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
