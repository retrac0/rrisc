#!/usr/bin/env bash
# Thin wrapper — the real runner is ../run_tests.py (RCC suite only).
set -euo pipefail
exec python3 "$(dirname "$0")/../run_tests.py" --only rcc "$@"
