#!/usr/bin/env bash
# Test runner for the rcc compiler.
# Run from the compiler/ directory: bash run_tests.sh
#
# Error tests  (err-*.c): compiler must exit non-zero; stderr must match .err.expect
# Success tests (NNN-*.c): compiler -> asm.py -> sim.py; output must match .output.expect
#
# Options:
#   --keep   Keep intermediate .s and .bin files after each test.

set -uo pipefail

KEEP=0
for arg in "$@"; do
    case $arg in
        --keep) KEEP=1 ;;
        *) echo "unknown option: $arg"; exit 1 ;;
    esac
done

# ---- locate tools ----
cabal build 2>&1 | grep -v "^Up to date" || true
RCC=$(cabal list-bin rcc 2>/dev/null)
ASM="python3 ../asm.py"
SIM="python3 ../sim.py"
SIM_FLAGS="--summary --start 0o1000 --maxcycle 100000"

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

pass=0
fail=0
skip=0

# ---- error tests ----
err_count=0
for src in tests/err-*.c; do
    base=$(basename "$src" .c)
    expect="tests/$base.err.expect"
    errfile="$TMPDIR_WORK/$base.err"

    echo -n "error test $base ... "
    if "$RCC" "$src" -o /dev/null 2>"$errfile"; then
        echo "FAIL (compiler did not reject input)"
        fail=$((fail + 1))
        continue
    fi

    if [ ! -f "$expect" ]; then
        echo "SKIP (no .err.expect)"
        skip=$((skip + 1))
        continue
    fi

    if cmp -s "$errfile" "$expect"; then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL (error message mismatch)"
        diff "$expect" "$errfile" || true
        fail=$((fail + 1))
    fi
    err_count=$((err_count + 1))
done
echo "error tests: $err_count checked"

# ---- success tests ----
ok_count=0
for src in tests/[0-9]*.c; do
    base=$(basename "$src" .c)
    expect="tests/$base.output.expect"
    asm_out="$TMPDIR_WORK/$base.s"
    bin_out="$TMPDIR_WORK/$base.bin"
    actual="$TMPDIR_WORK/$base.output"

    echo -n "compile test $base ... "

    # Stage 1: compile
    rcc_flags=""
    [ -f "tests/$base.rccflags" ] && rcc_flags=$(cat "tests/$base.rccflags")
    if ! "$RCC" $rcc_flags "$src" -o "$asm_out" 2>"$TMPDIR_WORK/$base.rcc.err"; then
        echo "FAIL (compiler error)"
        cat "$TMPDIR_WORK/$base.rcc.err"
        fail=$((fail + 1))
        continue
    fi

    # Stage 2: assemble
    if ! $ASM "$asm_out" 2>"$TMPDIR_WORK/$base.asm.err"; then
        echo "FAIL (assembler error)"
        cat "$TMPDIR_WORK/$base.asm.err"
        fail=$((fail + 1))
        continue
    fi

    # Stage 3: simulate
    extra_flags=""
    [ -f "tests/$base.simflags" ] && extra_flags=$(cat "tests/$base.simflags")
    $SIM $SIM_FLAGS $extra_flags "$bin_out" > "$actual" 2>&1

    if [ ! -f "$expect" ]; then
        echo "SKIP (no .output.expect)"
        skip=$((skip + 1))
    elif cmp -s "$actual" "$expect"; then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL (output mismatch)"
        diff "$expect" "$actual" || true
        fail=$((fail + 1))
    fi

    if [ "$KEEP" -eq 1 ]; then
        cp "$asm_out" "tests/$base.s.out"
        cp "$bin_out" "tests/$base.bin.out"
    fi

    ok_count=$((ok_count + 1))
done
echo "compile tests: $ok_count checked"

# ---- summary ----
echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
