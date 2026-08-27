#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$ROOT_DIR" <<'PY'
import sys
from pathlib import Path

source = (Path(sys.argv[1]) / "src/shared/Config/ProfileSchema.lua").read_text()
world = (Path(sys.argv[1]) / "src/shared/Config/WorldGenConfig.lua").read_text()
for marker in (
    "schemaVersion = ProfileSchema.CurrentVersion",
    "highestChapter = 0",
    "collectedKeys = {}",
    "bestChapterMs = {}",
    "totalDeaths = 0",
    "completionCount = 0",
    "reducedMotion = false",
    "reduceFlashes = false",
    "highContrast = false",
    "largeText = false",
    "lowParticles = false",
    "showTimer = true",
    "masterVolume = 1",
    "musicVolume = 1",
    "sfxVolume = 1",
    "uiScale = 1",
    "raw.highestChapter or legacyChapter",
    "validTime < 86400000",
    'type(raw.settings[key]) == "boolean"',
    "ProfileSchema.MaxCollectedKeys = 100",
    "ProfileSchema.MaxChapter = 18",
    "chapterNumber <= ProfileSchema.MaxChapter",
    "ProfileSchema.MaxChapter",
    "ProfileSchema.MaxCounter = 1000000000",
    "keyCount >= ProfileSchema.MaxCollectedKeys",
):
    if marker not in source:
        raise SystemExit(f"missing profile contract marker: {marker}")
stage_count = world.count('    "')
if stage_count != 18:
    raise SystemExit(f"canonical route stage count changed: {stage_count}")
print("profile contract ok: defaults, migration, bounds, settings, and key cap")
PY
