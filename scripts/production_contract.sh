#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }

grep -q 'Name = "GeneratedObby"' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generated ownership root missing"
grep -q 'GeneratorOwner' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generator ownership marker missing"
grep -q 'stageId = stageModel:GetAttribute("StageId")' "$ROOT_DIR/src/server/WorldGen/ZoneBuilder.lua" || fail "stage manifest IDs missing"
grep -q 'stageIndex <= previous' "$ROOT_DIR/src/server/Services/CheckpointService.lua" || fail "checkpoint regression guard missing"
if grep -q 'part:Destroy()' "$ROOT_DIR/src/server/Services/ObbyService.lua"; then
  fail "collectible runtime must not globally destroy keys"
fi
grep -q 'GeneratorVersion' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generator version missing"
grep -q 'AuthoredKeysPerChapter = 1' "$ROOT_DIR/src/shared/Config/GameConfig.lua" || fail "authored key contract missing"
grep -q 'GetObbyState' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "initial state request missing"
grep -q 'SetAccessibilitySettings' "$ROOT_DIR/src/shared/Network/RemoteContracts.lua" || fail "settings contract missing"
grep -q 'reducedMotion = true' "$ROOT_DIR/src/server/Services/ObbyService.lua" || fail "settings allowlist missing"
echo "production contracts ok"
