#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="/Users/padronavio/Projects/vio83-ai-orchestra"

exec "$SCRIPT_DIR/scripts/vscode_autopilot/vscode_maintenance_balanced.sh" --repo "$TARGET_REPO" --apply-presets "$@"
