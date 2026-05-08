#!/usr/bin/env bash
# Build relocatable object for the combined float runtime (lib/float/rrisc_float_bundle.s).
# Output: build/rrisc-float-obj/rrisc_float_bundle.o — link with hsld after RCC-generated .o.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-"$ROOT/build/rrisc-float-obj"}"
mkdir -p "$OUT"

HSASM="${HSASM:-}"
if [[ -z "$HSASM" ]]; then
  HSASM="$(cd "$ROOT/hstools" && cabal list-bin exe:hsasm 2>/dev/null | tail -1 || true)"
fi
if [[ -z "$HSASM" || ! -x "$HSASM" ]]; then
  echo "hsasm not found; set HSASM or run: cd hstools && cabal build exe:hsasm" >&2
  exit 1
fi

SRC="$ROOT/lib/float/rrisc_float_bundle.s"
tmpbin="$(mktemp "$OUT/.tmpbin.XXXXXX")"
"$HSASM" "$SRC" -I "$ROOT/lib" -o "$tmpbin" --emit-obj --obj-out "$OUT/rrisc_float_bundle.o"
rm -f "$tmpbin"
echo "Wrote $OUT/rrisc_float_bundle.o" >&2
