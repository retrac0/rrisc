#!/usr/bin/env bash
# Thin wrapper — the real runner is ./run_tests.py (assembler tests + examples).
set -euo pipefail
cd "$(dirname "$0")"
exec python3 ./run_tests.py --only asm,examples "$@"
