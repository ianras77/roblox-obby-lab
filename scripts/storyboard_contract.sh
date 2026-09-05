#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
luau tests/campaign_spec.lua
