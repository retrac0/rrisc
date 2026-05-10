# UART / dual-target IO tests

Sources under this directory are built twice: **RCC** → asm → ras/rld → simulators with `--terminal`, and **host gcc** with `-DRRISC_IO_TEST_HOST`. Both must match the same `*.stdout.expect` bytes.

## Adding a test

1. Add `yourcase.c` including `io_include.h` (selects `lib/rlibc_io.h` vs `lib/rlibc_host.h`).
2. Add hand-written `yourcase.stdout.expect` (exact UART/stdout bytes, final newline included if the program prints one).
3. If the program reads UART stdin, add `yourcase.input`; the harness passes it to sim and host exe.
4. Optional: `yourcase.rccflags` / `yourcase.simflags` (same mechanism as numbered RCC tests).

Run:

```bash
python3 run_tests.py --only io
```

## Host string literals

RCC `puts` takes `int*` (word-at-a-time strings). On the host, use the pattern from `matrix-print.c`:

```c
#if defined(RRISC_IO_TEST_HOST)
  rrisc_host_puts_cstr("banner\n");
#else
  /* word array for RCC */
#endif
```

## Refreshing goldens from gcc only

When gcc is available:

```bash
python3 run_tests.py --bless-io-host --filter 'yourcase'
```

This overwrites `*.stdout.expect` from the host binary. **You still must** run `--only io` so all simulators agree before committing; RCC and gcc can differ around edge cases.

## Policy

`--bless-output` only touches numbered `compiler/tests/[0-9]*.output.expect`. It never writes IO UART goldens.
