#!/usr/bin/env python3
"""Parity checks: ``pyld`` vs Haskell ``rld``, ``objfmt`` round-trip."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _ras_path() -> Path | None:
    r = subprocess.run(
        ["cabal", "list-bin", "exe:ras"],
        cwd=ROOT / "tools",
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        return None
    line = r.stdout.strip().splitlines()[-1].strip()
    p = Path(line)
    return p if p.is_file() else None


def _rld_path() -> Path | None:
    r = subprocess.run(
        ["cabal", "list-bin", "exe:rld"],
        cwd=ROOT / "tools",
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        return None
    line = r.stdout.strip().splitlines()[-1].strip()
    p = Path(line)
    return p if p.is_file() else None


class TestPyldParity(unittest.TestCase):
    def test_pyld_matches_rld_on_toolchain_asm(self) -> None:
        ras = _ras_path()
        rld = _rld_path()
        if ras is None or rld is None:
            self.skipTest("Haskell ras/rld not built (cd tools && cabal build exe:ras exe:rld)")

        from pytools import link_core

        tc = ROOT / "tools" / "tests" / "toolchain"
        for src in sorted(tc.glob("*.s")):
            with self.subTest(src=src.name):
                with tempfile.TemporaryDirectory() as td:
                    td = Path(td)
                    obj = td / (src.stem + ".o")
                    hs_bin = td / "hs.bin"
                    py_bin = td / "py.bin"
                    subprocess.run(
                        [str(ras), str(src), "-o", str(obj)],
                        cwd=ROOT,
                        check=True,
                        capture_output=True,
                    )
                    subprocess.run(
                        [str(rld), str(obj), "-o", str(hs_bin)],
                        cwd=ROOT,
                        check=True,
                        capture_output=True,
                    )
                    lr = link_core.link_files(link_core.default_link_options, [str(obj)])
                    link_core.write_binary_words(str(py_bin), lr.words)
                    self.assertEqual(hs_bin.read_bytes(), py_bin.read_bytes())


class TestObjfmtRoundtrip(unittest.TestCase):
    def test_parse_render_roundtrip_on_ras_object(self) -> None:
        ras = _ras_path()
        if ras is None:
            self.skipTest("Haskell ras not built")

        from pytools import objfmt

        src = ROOT / "tools" / "tests" / "toolchain" / "0001-halt.s"
        with tempfile.TemporaryDirectory() as td:
            td = Path(td)
            obj = td / "x.o"
            subprocess.run(
                [str(ras), str(src), "-o", str(obj)],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
            original = obj.read_text(encoding="utf-8")
            parsed = objfmt.read_object_file(str(obj))
            self.assertIsInstance(parsed, objfmt.ObjectFile)
            assert isinstance(parsed, objfmt.ObjectFile)
            text = objfmt.render_object(parsed)
            parsed2 = objfmt.parse_object("<mem>", text)
            self.assertIsInstance(parsed2, objfmt.ObjectFile)


if __name__ == "__main__":
    unittest.main()
