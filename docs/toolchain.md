# RRISC production toolchain

This document describes how to **build and wire together** the Haskell tools:
**`rcc`** (compiler frontend), **`rras`** (assembler), **`rrld`** (linker), and **`rrsim`** (simulator).
For the **language** definition (syntax, semantics, ABI summary), see
[`compiler/spec.md`](../compiler/spec.md) (**§11b** documents **`rcc` + rrisc-tools** at language-doc level).
For a **tutorial and everyday commands** (UART, memory layout, inline asm), see
[`compiler/MANUAL.md`](../compiler/MANUAL.md) (Part I §3 and Part IV reference).
[`run_tests.py`](../run_tests.py) and [`rrisc_toolchain.py`](../rrisc_toolchain.py)
encode the same defaults as CI.

Build everything from the repository root (see [`cabal.project`](../cabal.project)):

```bash
cabal update
cabal build exe:rcc exe:rras exe:rrld exe:rrsim
make sim2   # optional: C simulator for run_tests.py matrix
```

Install into a prefix (optional):

```bash
cabal install exe:rcc exe:rras exe:rrld exe:rrsim --overwrite-policy=always
```

Binaries are produced under `dist-newstyle/`; use `cabal list-bin exe:rras` (etc.) or add them to your `PATH`. The root [`Makefile`](../Makefile) targets `rras`, `rrld`, `rrsim`, and `rcc` build and then print `list-bin` paths (no repo-root symlinks).

## End-to-end flow (`rcc` + `tools/`)

1. **`rcc`** (`compiler/` cabal package) reads one `.c` file (optional host `cpp`) and prints RRISC **assembly** (`.s`): `%define RCC_CODE_BASE`, `RCC_DATA_BASE`, `RCC_STACK_TOP`, then `%include` of [`lib/crt0.s`](../lib/crt0.s), code, and data sections.
2. **`rras`** ([`tools/`](../tools/), package **`rrisc-tools`**) assembles `.s` to a relocatable **`.o`** by default (`-o` optional; same stem with `.o` if omitted). For a **flat** raw `.bin` or `$readmemb` **`.mem`**, pass **`--format bin`** or **`--format readmemb`** (see [`tools/app/Main.hs`](../tools/app/Main.hs)).
3. **`rrld`** links one or more `.o` files into a final image; bases must agree with the `%define` lines from step 1 (see contract below).
4. **`rrsim`** runs the binary; alternatives are **`python3 -m pytools.rrsim`** ([`pytools/rrsim.py`](../pytools/rrsim.py), same engine as [`pytools/sim.py`](../pytools/sim.py)) and **`sim2`** (built via `make sim2`). CI usually gates on the Python simulator only.

**Python counterparts** (same `rr*` spelling as the Haskell tools): **`rras`** (`python3 -m pytools.rras`), **`rrld`** (`python3 -m pytools.rrld`), **`rrsim`** (`python3 -m pytools.rrsim`). **`rrld`** implements the linker in Python and matches Haskell **`rrld`** on canonical `.o` inputs (see [`tests/pytools/test_link_parity.py`](../tests/pytools/test_link_parity.py)). **`rras`** emits relocatable `.o` files with the Python assembler by default (same textual format as the Haskell **`rras`**) and uses the same encoder for **`--format bin|readmemb`**. Legacy **`python3 -m pytools.asm`** remains for flat-only assembly.

Invoke tools from the repository root, or set **`PYTHONPATH`** to the repo root when the current working directory is elsewhere (see [`examples/Makefile`](../examples/Makefile) and [`demos/test_rpn.sh`](../demos/test_rpn.sh)).

For **`rcc` CLI flags** (`-O0`, `-Os`, `-O1`, `-O2` (alias of `-O1`), dumps, `--pass`, …), see [`compiler/app/Main.hs`](../compiler/app/Main.hs) and [`compiler/MANUAL.md`](../compiler/MANUAL.md) §13.

## Components

| Tool | Package | Role |
|------|---------|------|
| `rcc` | `compiler/` | C-like frontend → **assembly** (`.s`), not object files |
| `rras` | `rrisc-tools` (`tools/`) | Assembler → default **`.o`**; flat **`.bin`** / **`.mem`** with `--format` |
| `rrld` | `rrisc-tools` (`tools/`) | Linker → final `.bin` from one or more `.o` files |
| `rrsim` | `rrisc-tools` (`tools/`) | Haskell simulator (optional vs Python `rrsim` / `sim2`) |
| `rras` / `rrld` / `rrsim` (Python) | [`pytools/`](../pytools/) | Python CLI mirrors (`python -m pytools.rras` etc.); **`rrld`** is a full linker port |

Stable automation for tests and scripts lives in [`rrisc_toolchain.py`](../rrisc_toolchain.py) (path resolution, argv builders). Object / link checks are in [`toolchain_checks.py`](../toolchain_checks.py), including **`verify_rrld_matches_hs_rrld`**.

## rcc → rras → rrld contract

1. **Emitted prelude** — `rcc` prints `%define RCC_CODE_BASE`, `RCC_DATA_BASE`, and `RCC_STACK_TOP` (octal) near the top of generated assembly. The test harness and [`lib/crt0.s`](../lib/crt0.s) rely on these names.
2. **Sections** — Generated code uses `.section text` and, when needed, `.section data`. The linker places sections according to `rrld` options (e.g. `--code-base`, `--data-base`) and [`defaultLinkOptions`](../tools/src/RRISC/Link.hs).
3. **Startup** — Typical executables assemble **`crt0.o`** (stack init from `RCC_STACK_TOP`), **`librcc.o`** from [`lib/librcc.s`](../lib/librcc.s) (integer `__mul` / divide / modulo helpers used by `rcc`), then the compiler-produced `.o`, and link with `rrld` in that order using bases parsed from the `%define` lines (see [`run_tests.py`](../run_tests.py)). Soft-float stays separate under `lib/float/`.
4. **Symbols** — Cross-file visibility uses `.global` / extern semantics documented in [`compiler/MANUAL.md`](../compiler/MANUAL.md).

## Object file format versioning

- The text object format carries a version on the first line (`rrisc-obj N`). The canonical constant is [`objVersion`](../tools/src/RRISC/Obj/Format.hs) in `RRISC.Obj.Format`.
- **Bump `objVersion` only** when older `rrld` / `rras` must reject new `.o` files (breaking layout or record kinds). When bumping: document the change here, increment the field, and extend [`formatObjParseError`](../tools/src/RRISC/Obj/Format.hs) if new failure modes apply.

## CI vs local testing

- **CI** (`.github/workflows/ci.yml`) runs `cabal build`, `make sim2`, `cabal test` for Haskell suites, and:

  `python3 run_tests.py --only rcc,asm,toolchain,librcc --assemblers hs --simulators py`

  That tier is the **required** gate: Haskell assembler, Python simulator only (no `rrsim`/`sim2` requirement in CI).

- The **`librcc`** suite runs [`tools/tests/librcc/run_librcc_tests.py`](../tools/tests/librcc/run_librcc_tests.py): small linked programs call **`__mul`** / **`__udiv`** / **`__umod`** / **`__div`** / **`__mod`** from [`lib/librcc.s`](../lib/librcc.s) and assert **r2** at halt (no `rcc` required).

- The **`toolchain`** suite exercises [`toolchain_checks.py`](../toolchain_checks.py) on [`tools/tests/toolchain/*.s`](../tools/tests/toolchain/) only. Those files intentionally omit ``.org`` so the flat ``rras --format bin`` image matches a single-input ``rrld`` link (text placed at address 0). Programs that set ``.org 0o1000`` (most examples) produce a padded flat ``.bin`` that is **not** byte-identical to the packed link of the same ``.o``.

- **Local** runs may use `--simulators py,c,hs` and `--assemblers hs,py` for broader coverage; use `--skip-unavailable` when a binary is not built.

## Version flags

All of `rcc`, `rras`, `rrld`, and `rrsim` accept `-V` / `--version` (where applicable) and print the Cabal package version for the underlying package.
