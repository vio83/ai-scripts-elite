#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 /percorso/workspace.code-workspace" >&2
  exit 1
fi

WORKSPACE_PATH="$1"
CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

if [[ ! -f "$WORKSPACE_PATH" ]]; then
  echo "Workspace non trovato: $WORKSPACE_PATH" >&2
  exit 1
fi

if [[ -x "$CODE_BIN" ]]; then
  "$CODE_BIN" "$WORKSPACE_PATH"
else
  open -a "Visual Studio Code" "$WORKSPACE_PATH"
fi