#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/storyboard_contract.sh"
"$ROOT_DIR/scripts/production_contract.sh"
"$ROOT_DIR/scripts/config_contract.sh"
"$ROOT_DIR/scripts/profile_contract.sh"
luau "$ROOT_DIR/tests/progression_rules_spec.lua"
stylua --check src tests
selene src tests
