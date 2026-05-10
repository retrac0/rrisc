#!/usr/bin/env bash
# Build relocatable object for the combined float runtime (lib/float/rrisc_float_bundle.s).
# Output: build/rrisc-float-obj/rrisc_float_bundle.o — link with rld after RCC-generated .o.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-"$ROOT/build/rrisc-float-obj"}"
mkdir -p "$OUT"

RAS="${RAS:-}"
if [[ -z "$RAS" ]]; then
  RAS="$(cd "$ROOT/tools" && cabal list-bin exe:ras 2>/dev/null | tail -1 || true)"
fi
if [[ -z "$RAS" || ! -x "$RAS" ]]; then
  echo "ras not found; set RAS or run: cd tools && cabal build exe:ras" >&2
  exit 1
fi

SRC="$ROOT/lib/float/rrisc_float_bundle.s"
"$RAS" "$SRC" -I "$ROOT/lib" -o "$OUT/rrisc_float_bundle.o"
echo "Wrote $OUT/rrisc_float_bundle.o" >&2
