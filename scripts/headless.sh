#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LUNE_BIN=${LUNE_BIN:-lune}
ROJO_BIN=${ROJO_BIN:-rojo}
TMP_PLACE=$(mktemp /tmp/toads-headless.XXXXXX.rbxlx)
trap 'rm -f "$TMP_PLACE"' EXIT
"$ROJO_BIN" build "$ROOT_DIR/default.project.json" -o "$TMP_PLACE"
cd "$ROOT_DIR"
"$LUNE_BIN" run tests/headless/run.luau "$TMP_PLACE"
