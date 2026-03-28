#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
}

PROJECT_FILE=${1:-default.project.json}

require_cmd rojo
require_cmd stylua
require_cmd selene

cd "$ROOT_DIR"

rojo --version
stylua --version
selene --version

echo "Project root: $ROOT_DIR"
echo "Rojo project file: $PROJECT_FILE"
