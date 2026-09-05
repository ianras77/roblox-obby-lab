#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/source_contract.py
luau tests/movement_assist_spec.lua
