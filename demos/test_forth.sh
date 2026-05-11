#!/usr/bin/env bash
# demos/test_forth.sh — smoke-test demos/forth.bin (UART Forth-style demo).
#
# Build: make -C demos forth.bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$SCRIPT_DIR/forth.bin"
SIM_MAXCYCLE="${SIM_MAXCYCLE:-2000000}"
SIM=(
	env PYTHONPATH="$ROOT" python3 -m pytools.sim
	--terminal
	--mem ram:0:0o7770
	--start 0o100
	--maxcycle "$SIM_MAXCYCLE"
)

usage() {
	cat <<EOF
Usage: $(basename "$0") <command>

  smoke     UART-preload BYE + newline; expect clean halt (no cycle limit hit).
  run       Interactive UART session (same flags as smoke).
  commands  Print the simulator invocation.
  help      This text.

Environment:
  SIM_MAXCYCLE   Cycle limit (default 2000000). Set 0 for unlimited in run.

Examples (from repo root):

  make -C demos forth.bin
  ./demos/test_forth.sh smoke
EOF
}

cmd_commands() {
	printf '%q ' "${SIM[@]}"
	echo "$BIN"
}

cmd_smoke() {
	if [[ ! -f "$BIN" ]]; then
		echo "error: $BIN missing — run: make -C demos forth.bin" >&2
		exit 1
	fi
	# Guest echoes typed line then prints ok; BYE should halt the machine.
	# Use UART preload so stdin is not read (no pipe/TTY thread; works in CI/sandbox).
	"${SIM[@]}" --uart-preload $'BYE\n' "$BIN"
}

cmd_run() {
	if [[ ! -f "$BIN" ]]; then
		echo "error: $BIN missing — run: make -C demos forth.bin" >&2
		exit 1
	fi
	"${SIM[@]}" "$BIN"
}

main() {
	case "${1:-help}" in
		smoke) cmd_smoke ;;
		run) cmd_run ;;
		commands) cmd_commands ;;
		help|-h|--help) usage ;;
		*) usage; exit 1 ;;
	esac
}

main "$@"
