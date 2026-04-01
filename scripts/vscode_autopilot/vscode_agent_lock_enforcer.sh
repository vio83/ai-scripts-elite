#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${VIO_AGENT_LOCK_APP_DIR:-$HOME/Library/Application Support/VIO/vscode-agent-lock}"
STATE_DIR="$APP_DIR/state"
LOG_DIR="${VIO_AGENT_LOCK_LOG_DIR:-$HOME/Library/Logs/VIO/vscode-agent-lock}"
USER_DIR="${VIO_VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"
SETTINGS_PATH="$USER_DIR/settings.json"
PROMPTS_DIR="$USER_DIR/prompts"
TARGET_AGENT_PATH="$PROMPTS_DIR/ollama.agent.md"
BASELINE_SETTINGS="$STATE_DIR/settings.lock.json"
BASELINE_AGENT="$STATE_DIR/ollama.agent.md"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$PROMPTS_DIR"
LOG_FILE="$LOG_DIR/enforcer.log"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

if [[ ! -f "$BASELINE_SETTINGS" || ! -f "$BASELINE_AGENT" ]]; then
  log "ERRORE baseline mancante: eseguire prima install_vscode_agent_lock.sh"
  exit 1
fi

/usr/bin/env python3 - "$SETTINGS_PATH" "$BASELINE_SETTINGS" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
baseline_path = pathlib.Path(sys.argv[2])


def merge_dicts(base, patch):
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            merge_dicts(base[key], value)
        else:
            base[key] = value
    return base

if settings_path.exists():
    with settings_path.open("r", encoding="utf-8") as f:
        current = json.load(f)
else:
    current = {}

with baseline_path.open("r", encoding="utf-8") as f:
    baseline = json.load(f)

updated = merge_dicts(current, baseline)
settings_path.parent.mkdir(parents=True, exist_ok=True)
with settings_path.open("w", encoding="utf-8") as f:
    json.dump(updated, f, indent=2, ensure_ascii=True)
    f.write("\n")
PY

if [[ ! -f "$TARGET_AGENT_PATH" ]] || ! cmp -s "$BASELINE_AGENT" "$TARGET_AGENT_PATH"; then
  cp "$BASELINE_AGENT" "$TARGET_AGENT_PATH"
  log "Ripristinato $TARGET_AGENT_PATH"
fi

log "Enforcement completato"
