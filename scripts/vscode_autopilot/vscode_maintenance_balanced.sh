#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="/Users/padronavio/Projects/vio83-ai-orchestra"
TARGET_REPO="$DEFAULT_REPO"
MODE="balanced"
REOPEN=1
APPLY_PRESETS=1

if [[ -d "$SCRIPT_DIR/../presets" ]]; then
  PRESET_DIR="$(cd "$SCRIPT_DIR/../presets" && pwd)"
else
  PRESET_DIR="$SCRIPT_DIR"
fi

APP_DIR="$HOME/Library/Application Support/VIO/vscode-autopilot"
REPORT_DIR="$APP_DIR/reports"
LOCK_DIR="$APP_DIR/.lock"
VSCODE_DIR="$HOME/Library/Application Support/Code"
USER_DIR="$VSCODE_DIR/User"
WORKSPACE_STORAGE="$USER_DIR/workspaceStorage"
CACHED_DATA="$VSCODE_DIR/CachedData"
GPU_CACHE="$VSCODE_DIR/GPUCache"
LOGS_DIR="$VSCODE_DIR/logs"
OWN_LOG_DIR="$HOME/Library/Logs/VIO/vscode-autopilot"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
REPORT_PREFIX="$REPORT_DIR/$TIMESTAMP"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --no-reopen)
      REOPEN=0
      shift
      ;;
    --skip-presets)
      APPLY_PRESETS=0
      shift
      ;;
    --apply-presets)
      APPLY_PRESETS=1
      shift
      ;;
    *)
      echo "Argomento non supportato: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$APP_DIR" "$REPORT_DIR" "$OWN_LOG_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Autopilota gia' in esecuzione. Uscita." >&2
  exit 0
fi

cleanup_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

trap cleanup_lock EXIT

LOG_FILE="$OWN_LOG_DIR/maintenance_$TIMESTAMP.log"

log() {
  printf "%b%s%b\n" "$CYAN" "$1" "$NC"
  printf "%s\n" "$1" >> "$LOG_FILE"
}

resolve_code_bin() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return 0
  fi
  if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    printf "%s\n" "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    return 0
  fi
  return 1
}

CODE_BIN="$(resolve_code_bin || true)"

size_kb() {
  local target="$1"
  du -sk "$target" 2>/dev/null | awk '{print $1}'
}

report_cmd() {
  local label="$1"
  shift
  {
    printf "### %s\n" "$label"
    "$@"
    printf "\n"
  } >> "$REPORT_PREFIX.report.md" 2>&1 || true
}

printf "%b==============================================%b\n" "$CYAN" "$NC"
printf "%bVIO VS CODE AUTOPILOT MAINTENANCE%b\n" "$BOLD" "$NC"
printf "%b==============================================%b\n\n" "$CYAN" "$NC"

log "Modalita': $MODE"
log "Repo target: $TARGET_REPO"

find "$OWN_LOG_DIR" -type f -mtime +30 -delete 2>/dev/null || true

if [[ -n "$CODE_BIN" ]]; then
  report_cmd "Installed Extensions" "$CODE_BIN" --list-extensions --show-versions
fi

log "Chiusura VS Code"
osascript -e 'tell application "Visual Studio Code" to quit' >/dev/null 2>&1 || true
sleep 2

log "Pulizia log VS Code piu' vecchi di 14 giorni"
find "$LOGS_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} + 2>/dev/null || true

log "Pulizia workspaceStorage piu' vecchio di 21 giorni"
find "$WORKSPACE_STORAGE" -mindepth 1 -maxdepth 1 -type d -mtime +21 -exec rm -rf {} + 2>/dev/null || true

GPU_KB="$(size_kb "$GPU_CACHE" || echo 0)"
if [[ "${GPU_KB:-0}" -gt 524288 ]]; then
  log "GPUCache sopra soglia: pulizia eseguita"
  rm -rf "$GPU_CACHE"/* 2>/dev/null || true
else
  log "GPUCache sotto soglia: nessuna pulizia aggressiva"
fi

if [[ "$MODE" == "deep" ]]; then
  CACHED_KB="$(size_kb "$CACHED_DATA" || echo 0)"
  if [[ "${CACHED_KB:-0}" -gt 2097152 ]]; then
    log "CachedData sopra soglia deep: pulizia eseguita"
    rm -rf "$CACHED_DATA"/* 2>/dev/null || true
  else
    log "CachedData deep sotto soglia: nessuna pulizia"
  fi
fi

if [[ "$APPLY_PRESETS" -eq 1 && -d "$TARGET_REPO" ]]; then
  log "Applicazione preset performance a VIO AI Orchestra"
  /usr/bin/env python3 "$SCRIPT_DIR/merge_vscode_settings.py" \
    "$TARGET_REPO/.vscode/settings.json" \
    "$PRESET_DIR/preset_base.settings.json" \
    "$PRESET_DIR/preset_react_typescript.settings.json" \
    "$PRESET_DIR/preset_python_fastapi.settings.json" \
    "$PRESET_DIR/preset_tauri_rust.settings.json" >> "$LOG_FILE" 2>&1
else
  log "Preset non applicati"
fi

if [[ "$REOPEN" -eq 1 ]]; then
  if [[ -d "$TARGET_REPO" ]]; then
    log "Riapertura repo target in VS Code"
    open -a "Visual Studio Code" "$TARGET_REPO" >/dev/null 2>&1 || true
  else
    log "Riapertura app VS Code"
    open -a "Visual Studio Code" >/dev/null 2>&1 || true
  fi
  sleep 8
fi

if [[ -n "$CODE_BIN" ]]; then
  report_cmd "Code Status" "$CODE_BIN" --status
fi

{
  printf "timestamp=%s\n" "$TIMESTAMP"
  printf "mode=%s\n" "$MODE"
  printf "target_repo=%s\n" "$TARGET_REPO"
  printf "gpu_cache_kb=%s\n" "${GPU_KB:-0}"
} > "$REPORT_PREFIX.summary.txt"

printf "\n%bCompletato.%b Report: %s\n" "$GREEN" "$NC" "$REPORT_PREFIX.summary.txt"
