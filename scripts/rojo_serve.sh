#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROJECT_FILE=${1:-${ROJO_PROJECT:-default.project.json}}
PROJECT_PORT=$(sed -n 's/.*"servePort": *\([0-9][0-9]*\).*/\1/p' "$ROOT_DIR/$PROJECT_FILE" | head -n 1)
ROJO_PORT=${2:-${ROJO_PORT:-${PROJECT_PORT:-34872}}}

cd "$ROOT_DIR"
rojo serve --address 0.0.0.0 --port "$ROJO_PORT" "$PROJECT_FILE"
