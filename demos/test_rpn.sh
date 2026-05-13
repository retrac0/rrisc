#!/usr/bin/env bash
# demos/test_rpn.sh — small harness showing how to exercise rpn.bin from the shell.
#
# Prerequisites (repo root): built demo binary at demos/rpn.bin — run:
#   make -C demos
# or follow the commands printed by:  ./demos/test_rpn.sh commands
#
# The simulator needs --terminal (UART), the same flat RAM map as the Makefile,
# and --start set to the code entry (RCC_CODE_BASE in the generated .s file).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$SCRIPT_DIR/rpn.bin"
# Cap simulator cycles so UART/getchar bugs cannot hang CI or your shell (loop errors).
# Interactive use: SIM_MAXCYCLE=0 ./demos/test_rpn.sh run  (0 = unlimited in pytools.rrsim)
SIM_MAXCYCLE="${SIM_MAXCYCLE:-2000000}"
SIM=(
	env PYTHONPATH="$ROOT" python3 -m pytools.rrsim
	--terminal
	--mem ram:0:0o7770
	--start 0o100
	--maxcycle "$SIM_MAXCYCLE"
)

usage() {
	cat <<EOF
Usage: $(basename "$0") <command>

  smoke       Runs the full UART equation suite (~20 cases) then reports ok.
  equations   Same suite as smoke (for an explicit name in CI logs).
  run         Run the simulator on $BIN (stdin/stdout are the UART).
  commands    Print the underlying shell commands (copy/paste or script them).
  help        This text.

Environment:
  SIM_MAXCYCLE   Cycle limit for pytools.rrsim (default 2000000). Set to 0 for no limit (mainly for run).
  SIM_EXTRA      Extra arguments passed to pytools.rrsim before the binary (after built-in flags).

Examples (from repo root after make -C demos):

  # Full UART regression (20 RPN lines vs expected hex)
  ./demos/test_rpn.sh equations

  # One-off: stack holds 3 and 4, add, print top, quit (UART includes guest echo of typed lines)
  printf '%s\\n' '3 4 +' p q | env PYTHONPATH=. python3 -m pytools.rrsim --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin

  # Interactive (same UART flags): type lines, then q to exit
  SIM_MAXCYCLE=0 env PYTHONPATH=. python3 -m pytools.rrsim --terminal --mem ram:0:0o7770 --start 0o100 demos/rpn.bin
EOF
}

need_bin() {
	if [[ ! -f "$BIN" ]]; then
		echo "Missing $BIN — build first:  make -C demos" >&2
		exit 1
	fi
}

# Run stdin through the simulator; return UART stdout as lowercase hex (no spaces).
uart_hex() {
	printf '%s' "$1" | "${SIM[@]}" ${SIM_EXTRA:-} "$BIN" 2>/dev/null | xxd -p | tr -d '\n' || true
}

# Decode contiguous lowercase hex to bytes; show with non-printables visible (newline -> ^J).
uart_hex_visible() {
	local h="$1"
	if [[ -z "$h" ]]; then
		echo "<empty>"
		return
	fi
	printf '%s' "$h" | xxd -r -p 2>/dev/null | cat -v
}

# Each test: one line of RPN ending with p (print top), then q on the next line (two gets() lines).
# Expected value is the exact UART byte sequence: guest echoes each line read by gets(), then
# puts() adds a newline after itoa for `p`.
cmd_equations() {
	need_bin
	local fails=0 n=0
	run_one() {
		local desc="$1" input="$2" want="$3" got want_vis got_vis
		n=$((n + 1))
		got="$(uart_hex "$input")"
		want_vis="$(uart_hex_visible "$want")"
		got_vis="$(uart_hex_visible "$got")"
		echo "#${n} ${desc}"
		echo "  input (stdin to calculator, one line per gets):"
		printf '%s' "${input}" | awk 'length { print "    [" ++i "] " $0 }'
		echo "  expected UART (echo + print + newline from puts): ${want_vis}"
		echo "  expected hex:  ${want}"
		echo "  got UART (echo + print + newline from puts):      ${got_vis}"
		echo "  got hex:       ${got:-<empty>}"
		if [[ "$got" != "$want" ]]; then
			echo "  -> FAIL" >&2
			fails=$((fails + 1))
		else
			echo "  -> ok"
		fi
		echo ""
	}

	# --- arithmetic ---
	run_one "3 + 4" $'3 4 + p\nq\n' "332034202b20700a370a710a"
	run_one "1 + 2 + 3" $'1 2 3 + + p\nq\n' "3120322033202b202b20700a360a710a"
	run_one "10 - 3" $'10 3 - p\nq\n' "31302033202d20700a370a710a"
	run_one "6 * 7" $'6 7 * p\nq\n' "362037202a20700a34320a710a"
	run_one "10 / 2" $'10 2 / p\nq\n' "31302032202f20700a350a710a"
	run_one "15 / 4 trunc" $'15 4 / p\nq\n' "31352034202f20700a330a710a"
	run_one "1 * 2 * 3" $'1 2 * 3 * p\nq\n' "312032202a2033202a20700a360a710a"
	run_one "8 * 3 / 2" $'8 3 * 2 / p\nq\n' "382033202a2032202f20700a31320a710a"
	run_one "11 + 11" $'11 11 + p\nq\n' "3131203131202b20700a32320a710a"
	run_one "100 + 200" $'100 200 + p\nq\n' "31303020323030202b20700a3330300a710a"
	# 12-bit word wrap (unsigned view of sum)
	run_one "4000 + 500 (12-bit)" $'4000 500 + p\nq\n' "3430303020353030202b20700a3430340a710a"
	# signed MIN edge for itoa (2047 + 1 == -2048)
	run_one "2047 + 1 wrap" $'2047 1 + p\nq\n' "323034372031202b20700a2d323034380a710a"
	run_one "2047 - 2047" $'2047 2047 - p\nq\n' "323034372032303437202d20700a300a710a"
	# --- unary / stack ops ---
	run_one "negate 5" $'5 n p\nq\n' "35206e20700a2d350a710a"
	run_one "dup then +" $'3 d + p\nq\n' "332064202b20700a360a710a"
	run_one "clear then 1" $'9 8 c 1 p\nq\n' "3920382063203120700a310a710a"
	run_one "print lone 0" $'0 p\nq\n' "3020700a300a710a"
	run_one "-12 + 3" $'-12 3 + p\nq\n' "2d31322033202b20700a2d390a710a"
	run_one "(0 - 7) / 2" $'0 7 - 2 / p\nq\n' "302037202d2032202f20700a2d330a710a"
	run_one "3 * 4 then negate" $'3 4 * n p\nq\n' "332034202a206e20700a2d31320a710a"

	if [[ "$fails" -ne 0 ]]; then
		echo "equations: $fails failure(s) out of $n" >&2
		exit 1
	fi
	echo "equations ok ($n UART checks, expected hex vs pytools.rrsim UART)"
}

cmd_smoke() {
	cmd_equations
}

cmd_run() {
	need_bin
	exec "${SIM[@]}" ${SIM_EXTRA:-} "$BIN"
}

cmd_commands() {
	cat <<EOF
# --- Build (from repo root) ---
make -C demos

# --- Same UART checks as:  ./demos/test_rpn.sh equations  (20 expected hex vs stdout) ---
printf '%s' \$'3 4 + p\\nq\\n' | \\
  env PYTHONPATH=. python3 -m pytools.rrsim --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin

# --- Interactive session (no cycle cap) ---
env PYTHONPATH=. python3 -m pytools.rrsim --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 0 demos/rpn.bin

# --- Haskell simulator (if built): add --maxcycle as supported ---
# rrsim --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin
EOF
}

main() {
	local cmd="${1:-help}"
	case "$cmd" in
		smoke)     cmd_smoke ;;
		equations) cmd_equations ;;
		run)       cmd_run ;;
		commands)  cmd_commands ;;
		help|-h|--help) usage ;;
		*)
			echo "Unknown command: $cmd" >&2
			usage >&2
			exit 1
			;;
	esac
}

main "$@"
