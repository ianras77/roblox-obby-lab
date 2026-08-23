#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }

grep -q 'Name = "GeneratedObby"' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generated ownership root missing"
grep -q 'GeneratorOwner' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generator ownership marker missing"
grep -q 'stageId = result.model:GetAttribute("StageId")' "$ROOT_DIR/src/server/WorldGen/ZoneBuilder.lua" || fail "stage manifest IDs missing"
grep -q 'stageIndex <= previous' "$ROOT_DIR/src/server/Services/CheckpointService.lua" || fail "checkpoint regression guard missing"
if grep -q 'part:Destroy()' "$ROOT_DIR/src/server/Services/ObbyService.lua"; then
  fail "collectible runtime must not globally destroy keys"
fi
grep -q 'GeneratorVersion' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "generator version missing"
grep -q 'AuthoredKeysPerChapter = 1' "$ROOT_DIR/src/shared/Config/GameConfig.lua" || fail "authored key contract missing"
grep -q 'GetObbyState' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua" || fail "initial state request missing"
if grep -q 'progressEvent:FireAllClients' "$ROOT_DIR/src/server/WorldGen/WorldBuilder.lua"; then fail "startup state must not broadcast globally"; fi
if grep -q 'celebrator.Parent = checkpoint' "$ROOT_DIR/src/server/Services/CheckpointService.lua"; then fail "finale burst must not be shared"; fi
grep -q 'SetAccessibilitySettings' "$ROOT_DIR/src/shared/Network/RemoteContracts.lua" || fail "settings contract missing"
grep -q 'reducedMotion = true' "$ROOT_DIR/src/server/Services/ObbyService.lua" || fail "settings allowlist missing"
grep -q 'Magnitude <= 18' "$ROOT_DIR/src/server/Services/CheckpointService.lua" || fail "checkpoint distance validation missing"
grep -q 'Magnitude > 18' "$ROOT_DIR/src/server/Services/ObbyService.lua" || fail "key distance validation missing"
grep -q 'SetRunMode' "$ROOT_DIR/src/shared/Network/RemoteContracts.lua" || fail "run mode contract missing"
grep -q 'showResults' "$ROOT_DIR/src/client/Controllers/UIController.lua" || fail "results presentation missing"
grep -q 'MaxDevSeed' "$ROOT_DIR/src/shared/Config/GameConfig.lua" || fail "dev seed cap missing"
grep -q 'SaveCheckpoints = true' "$ROOT_DIR/src/shared/Config/GameConfig.lua" || fail "production persistence default missing"
grep -q 'player:" .. tostring(player.UserId)' "$ROOT_DIR/src/server/Services/CheckpointService.lua" || fail "string datastore key missing"
grep -q 'DevCommandCooldownSeconds' "$ROOT_DIR/src/server/Services/ObbyService.lua" || fail "dev command rate limit missing"
grep -q 'approvedForRelease' "$ROOT_DIR/src/shared/Config/AssetRegistry.lua" || fail "asset approval registry missing"
grep -q 'playFirstApprovedMusic' "$ROOT_DIR/src/server/ServerMain.server.lua" || fail "asset approval gate missing"
grep -q 'ChapterFlavor' "$ROOT_DIR/src/server/WorldGen/StageBuilder.lua" || fail "chapter presentation metadata missing"
grep -q 'StageBuildResult' "$ROOT_DIR/src/server/WorldGen/StageBuilder.lua" || fail "explicit stage build result missing"
grep -q 'duplicate collectible id' "$ROOT_DIR/src/server/WorldGen/WorldValidator.lua" || fail "duplicate collectible validation missing"
echo "production contracts ok"
