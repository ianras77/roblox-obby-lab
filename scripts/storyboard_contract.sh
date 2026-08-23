#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mapfile -t stage_types < <(
  awk '
    /StageTypes[[:space:]]*=[[:space:]]*{/ {
      in_stage_types = 1
      next
    }
    in_stage_types && /^[[:space:]]*},/ {
      exit
    }
    in_stage_types {
      if (match($0, /"[^"]+"/)) {
        stage = substr($0, RSTART + 1, RLENGTH - 2)
        print stage
      }
    }
  ' "$ROOT_DIR/src/shared/Config/WorldGenConfig.lua"
)

if [[ "${#stage_types[@]}" -ne 18 ]]; then
  fail "expected 18 configured stages, found ${#stage_types[@]}: ${stage_types[*]}"
fi

missing=()
for stage_type in "${stage_types[@]}"; do
  if ! grep -Eq "function[[:space:]]+StageTemplates\.${stage_type}[[:space:]]*\("     "$ROOT_DIR/src/server/WorldGen/Templates/StageTemplates.lua"; then
    missing+=("$stage_type")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  fail "missing StageTemplates functions for: ${missing[*]}"
fi

if ! grep -q 'Title = "Toad' "$ROOT_DIR/src/shared/Config/GameConfig.lua"; then
  fail "GameConfig.lua must define a Toad-themed Title"
fi

if ! grep -q "Wind in the Willows" "$ROOT_DIR/README_KIDS.md"; then
  fail "README_KIDS.md must identify the book-homage theme"
fi

echo "storyboard contract ok"
