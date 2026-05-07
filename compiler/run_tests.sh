#!/usr/bin/env bash
# Test runner for the rcc compiler.
# Run from the compiler/ directory: bash run_tests.sh
#
# Error tests  (err-*.c): compiler must exit non-zero; stderr must match .err.expect
# Success tests (NNN-*.c): compiler -> asm.py -> sim.py; output must match .output.expect
#
# Options:
#   --keep      Keep intermediate .s and .bin files after each test.
#   --jobs N    Number of parallel jobs (default: nproc)
#   --filter P  Only run tests matching pattern P (passed to grep)

set -uo pipefail

KEEP=0
JOBS=$(nproc 2>/dev/null || echo 4)
FILTER=""
for arg in "$@"; do
    case $arg in
        --keep)   KEEP=1 ;;
        --jobs)   shift; JOBS=$1 ;;
        --jobs=*) JOBS="${arg#--jobs=}" ;;
        --filter) shift; FILTER=$1 ;;
        --filter=*) FILTER="${arg#--filter=}" ;;
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

# ---- result accumulation (via temp files, safe under parallelism) ----
PASS_DIR="$TMPDIR_WORK/pass"
FAIL_DIR="$TMPDIR_WORK/fail"
SKIP_DIR="$TMPDIR_WORK/skip"
mkdir -p "$PASS_DIR" "$FAIL_DIR" "$SKIP_DIR"

# ---- error tests (sequential, fast) ----
err_count=0
err_pass=0
err_fail=0
for src in tests/err-*.c; do
    base=$(basename "$src" .c)
    [ -n "$FILTER" ] && ! echo "$base" | grep -q "$FILTER" && continue
    expect="tests/$base.err.expect"
    errfile="$TMPDIR_WORK/$base.err"

    echo -n "error test $base ... "
    if "$RCC" "$src" -o /dev/null 2>"$errfile"; then
        echo "FAIL (compiler did not reject input)"
        err_fail=$((err_fail + 1))
        continue
    fi

    if [ ! -f "$expect" ]; then
        echo "SKIP (no .err.expect)"
        continue
    fi

    if cmp -s "$errfile" "$expect"; then
        echo "PASS"
        err_pass=$((err_pass + 1))
    else
        echo "FAIL (error message mismatch)"
        diff "$expect" "$errfile" || true
        err_fail=$((err_fail + 1))
    fi
    err_count=$((err_count + 1))
done
echo "error tests: $err_count checked"

# ---- success tests: run one test, write result to a file ----
run_one() {
    local src="$1"
    local base
    base=$(basename "$src" .c)
    local expect="tests/$base.output.expect"
    local asm_out="$TMPDIR_WORK/$base.s"
    local bin_out="$TMPDIR_WORK/$base.bin"
    local actual="$TMPDIR_WORK/$base.output"
    local result_file="$TMPDIR_WORK/result_$base"

    # Stage 1: compile
    local rcc_flags=""
    [ -f "tests/$base.rccflags" ] && rcc_flags=$(cat "tests/$base.rccflags")
    if ! "$RCC" $rcc_flags "$src" -o "$asm_out" 2>"$TMPDIR_WORK/$base.rcc.err"; then
        echo "FAIL (compiler error)"      >> "$result_file"
        cat "$TMPDIR_WORK/$base.rcc.err"  >> "$result_file"
        touch "$FAIL_DIR/$base"
        return
    fi

    # Stage 2: check assembly against .s.expect if present
    local s_expect="tests/$base.s.expect"
    if [ -f "$s_expect" ] && ! cmp -s "$asm_out" "$s_expect"; then
        echo "FAIL (assembly mismatch)"   >> "$result_file"
        diff "$s_expect" "$asm_out"       >> "$result_file" 2>&1 || true
        touch "$FAIL_DIR/$base"
        return
    fi

    # Stage 3: assemble
    if ! $ASM "$asm_out" -o "$bin_out" 2>"$TMPDIR_WORK/$base.asm.err"; then
        echo "FAIL (assembler error)"     >> "$result_file"
        cat "$TMPDIR_WORK/$base.asm.err"  >> "$result_file"
        touch "$FAIL_DIR/$base"
        return
    fi

    # Stage 4: simulate
    local extra_flags=""
    [ -f "tests/$base.simflags" ] && extra_flags=$(cat "tests/$base.simflags")
    $SIM $SIM_FLAGS $extra_flags "$bin_out" > "$actual" 2>&1

    if [ ! -f "$expect" ]; then
        echo "SKIP (no .output.expect)"   >> "$result_file"
        touch "$SKIP_DIR/$base"
    elif cmp -s "$actual" "$expect"; then
        echo "PASS"                        >> "$result_file"
        touch "$PASS_DIR/$base"
    else
        echo "FAIL (output mismatch)"     >> "$result_file"
        diff "$expect" "$actual"          >> "$result_file" 2>&1 || true
        touch "$FAIL_DIR/$base"
    fi

    if [ "$KEEP" -eq 1 ]; then
        cp "$asm_out" "tests/$base.s.out"
        cp "$bin_out" "tests/$base.bin.out"
    fi
}

export -f run_one
export RCC ASM SIM SIM_FLAGS TMPDIR_WORK KEEP PASS_DIR FAIL_DIR SKIP_DIR

# ---- collect test sources ----
mapfile -t SRCS < <(
    for src in tests/[0-9]*.c; do
        base=$(basename "$src" .c)
        [ -n "$FILTER" ] && ! echo "$base" | grep -q "$FILTER" && continue
        echo "$src"
    done
)

ok_count=${#SRCS[@]}

# ---- run tests in parallel via xargs ----
printf '%s\n' "${SRCS[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}

# ---- print results in sorted order ----
for src in "${SRCS[@]}"; do
    base=$(basename "$src" .c)
    result_file="$TMPDIR_WORK/result_$base"
    result=$(cat "$result_file" 2>/dev/null | head -1)
    echo "compile test $base ... $result"
    # Print extra lines (diffs, errors) for failures
    if [ -f "$FAIL_DIR/$base" ]; then
        tail -n +2 "$result_file" 2>/dev/null || true
    fi
done

pass=$(ls "$PASS_DIR" 2>/dev/null | wc -l)
fail=$(($(ls "$FAIL_DIR" 2>/dev/null | wc -l) + err_fail))
skip=$(ls "$SKIP_DIR" 2>/dev/null | wc -l)

echo "compile tests: $ok_count checked"
echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
