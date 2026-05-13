#!/usr/bin/env bash
# forth/test_forth.sh — UART smoke for forth/forth.bin (flat RAM 0o7770 words, --start 0o100).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$SCRIPT_DIR/forth.bin"
SIM_MAXCYCLE="${SIM_MAXCYCLE:-500000}"
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

  smoke       UART preload: 1 2 + then BYE; checks expected bytes vs pytools.rrsim.
  run         Interactive UART (stdin/stdout); end session with BYE to halt.
  help        This text.

Build first (from repo root):  make -C forth all
EOF
}

need_bin() {
	if [[ ! -f "$BIN" ]]; then
		echo "Missing $BIN — build first:  make -C forth all" >&2
		exit 1
	fi
}

# Guest echoes lines; interpreter prints leading "ok " before each UART line.
cmd_smoke() {
	need_bin
	local want1 got1 want2 got2
	want1="0a727269736320666f7274680a6f6b20312032202b0a6f6b204259450a"
	got1="$(printf '%s\n' '1 2 +' 'BYE' | "${SIM[@]}" ${SIM_EXTRA:-} "$BIN" 2>/dev/null | xxd -p | tr -d '\n' || true)"
	if [[ "$got1" != "$want1" ]]; then
		echo "forth smoke (1 2 +): UART mismatch" >&2
		echo "  want hex: $want1" >&2
		echo "  got hex:  ${got1:-<empty>}" >&2
		exit 1
	fi
	# Full line of words then "." must print octal + space (7 ) before next ok.
	want2="0a727269736320666f7274680a6f6b20332034202b202e0a37206f6b204259450a"
	got2="$(printf '%s\n' '3 4 + .' 'BYE' | "${SIM[@]}" ${SIM_EXTRA:-} "$BIN" 2>/dev/null | xxd -p | tr -d '\n' || true)"
	if [[ "$got2" != "$want2" ]]; then
		echo "forth smoke (3 4 + .): UART mismatch" >&2
		echo "  want hex: $want2" >&2
		echo "  got hex:  ${got2:-<empty>}" >&2
		exit 1
	fi
	echo "forth smoke ok"
}

cmd_run() {
	need_bin
	exec "${SIM[@]}" ${SIM_EXTRA:-} "$BIN"
}

main() {
	case "${1:-help}" in
		smoke) cmd_smoke ;;
		run) cmd_run ;;
		help | -h | --help) usage ;;
		*)
			echo "Unknown command: ${1:-}" >&2
			usage >&2
			exit 1
			;;
	esac
}

main "$@"
