# Numbered RCC tests (`compiler/tests/[0-9]*.c`)

## Sidecars (optional)

- `stem.rccflags` — extra `rcc` argv (whitespace-separated tokens)
- `stem.simflags` — extra simulator argv
- `stem.input` — stdin for the linked test binary

## Golden files

- **Assembly** — either all three of `stem.s.expect.O0`, `stem.s.expect.Os`, `stem.s.expect.O1`, or (legacy) a single `stem.s.expect` matching default `-Os` asm only.
- **Simulator stdout** — `stem.output.expect` and `stem.output.expect.O0` are both required if either exists (paired `-Os` / `-O0` builds). Refreshed with `python3 run_tests.py --bless-output` from the repo root.

Error tests use `err-*.c` with `stem.err.expect` for `rcc` stderr.

UART / host-gcc tests live under `io/`; see `io/README.md`.
