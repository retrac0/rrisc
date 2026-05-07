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
# Interactive use: SIM_MAXCYCLE=0 ./demos/test_rpn.sh run  (0 = unlimited in sim.py)
SIM_MAXCYCLE="${SIM_MAXCYCLE:-2000000}"
SIM=(
	python3 "$ROOT/sim.py"
	--terminal
	--mem ram:0:0o7770
	--start 0o100
	--maxcycle "$SIM_MAXCYCLE"
)

usage() {
	cat <<EOF
Usage: $(basename "$0") <command>

  smoke     Non-interactive check: 3 + 4 = 7, then quit (prints one line).
  run       Run the simulator on $BIN (stdin/stdout are the UART).
  commands  Print the underlying shell commands (copy/paste or script them).
  help      This text.

Environment:
  SIM_MAXCYCLE   Cycle limit for sim.py (default 2000000). Set to 0 for no limit (mainly for run).
  SIM_EXTRA      Extra arguments passed to sim.py before the binary (after built-in flags).

Examples (from repo root after make -C demos):

  # Automated line check
  ./demos/test_rpn.sh smoke

  # One-off: stack holds 3 and 4, add, print top, quit
  printf '%s\\n' '3 4 +' p q | python3 sim.py --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin

  # Interactive (same UART flags): type lines, then q to exit
  SIM_MAXCYCLE=0 python3 sim.py --terminal --mem ram:0:0o7770 --start 0o100 demos/rpn.bin
EOF
}

need_bin() {
	if [[ ! -f "$BIN" ]]; then
		echo "Missing $BIN — build first:  make -C demos" >&2
		exit 1
	fi
}

cmd_smoke() {
	need_bin
	# Use \$'...' so \\n is a real newline for gets().
	local input=$'3 4 + p\nq\n'
	# Command substitution strips one trailing newline from simulator stdout; compare bytes.
	local hex
	hex="$(printf '%s' "$input" | "${SIM[@]}" ${SIM_EXTRA:-} "$BIN" 2>/dev/null | xxd -p | tr -d '\n')" || true
	if [[ "$hex" == "370a" ]]; then
		echo "smoke ok: UART printed 0x37 ('7') then 0x0a (newline from puts)"
	else
		echo "smoke FAIL: expected hex bytes 370a, got: ${hex:-<empty>}" >&2
		exit 1
	fi
}

cmd_run() {
	need_bin
	exec "${SIM[@]}" ${SIM_EXTRA:-} "$BIN"
}

cmd_commands() {
	cat <<EOF
# --- Build (from repo root) ---
make -C demos

# --- Same as this script's smoke test (see SIM_MAXCYCLE in script; default 2M cycles) ---
printf '%s' \$'3 4 + p\\nq\\n' | \\
  python3 sim.py --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin

# --- Interactive session (no cycle cap) ---
python3 sim.py --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 0 demos/rpn.bin

# --- Haskell simulator (if built): add --maxcycle as supported ---
# rsim --terminal --mem ram:0:0o7770 --start 0o100 --maxcycle 2000000 demos/rpn.bin
EOF
}

main() {
	local cmd="${1:-help}"
	case "$cmd" in
		smoke)    cmd_smoke ;;
		run)      cmd_run ;;
		commands) cmd_commands ;;
		help|-h|--help) usage ;;
		*)
			echo "Unknown command: $cmd" >&2
			usage >&2
			exit 1
			;;
	esac
}

main "$@"
