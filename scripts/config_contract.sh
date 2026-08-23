#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$ROOT_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
world = (root / "src/shared/Config/WorldGenConfig.lua").read_text()
chapters = (root / "src/shared/Config/ChapterConfig.lua").read_text()
stage = (root / "src/shared/Config/StageConfig.lua").read_text()

stage_block = re.search(r"StageTypes\s*=\s*\{(.*?)\n\s*\},", world, re.S)
display_block = re.search(r"StageDisplayNames\s*=\s*\{(.*?)\n\s*\},", world, re.S)
if not stage_block or not display_block:
    raise SystemExit("canonical stage tables missing")
stage_types = re.findall(r'"([A-Za-z]+)"', stage_block.group(1))
display_names = re.findall(r"^\s*([A-Za-z]+)\s*=\s*\"", display_block.group(1), re.M)
chapter_keys = re.findall(r"^\s*([A-Za-z]+)\s*=\s*\{", chapters, re.M)
if len(stage_types) != 18 or len(set(stage_types)) != 18:
    raise SystemExit(f"expected 18 unique stage types, found {len(stage_types)}")
if display_names != stage_types:
    raise SystemExit("display names do not match canonical stage order")
if chapter_keys != stage_types:
    raise SystemExit("chapter metadata does not match canonical stage order")
if "id = string.lower(stageType" not in stage:
    raise SystemExit("stable stage ID derivation is missing")
print("config contract ok: 18 unique ordered chapters with matching metadata")
PY
