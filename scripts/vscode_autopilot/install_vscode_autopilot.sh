#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/Library/Application Support/VIO/vscode-autopilot"
BIN_DIR="$APP_DIR/bin"
PRESET_DIR="$APP_DIR/presets"
LOG_DIR="$HOME/Library/Logs/VIO/vscode-autopilot"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PATH="$LAUNCH_AGENT_DIR/com.vio.vscode-autopilot.plist"
WRAPPER_DIR="$HOME/.local/bin"
WRAPPER_PATH="$WRAPPER_DIR/vio-vscode-autopilot-now"
TARGET_REPO="/Users/padronavio/Projects/vio83-ai-orchestra"
RUN_NOW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --run-now)
      RUN_NOW=1
      shift
      ;;
    *)
      echo "Argomento non supportato: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$BIN_DIR" "$PRESET_DIR" "$LOG_DIR" "$LAUNCH_AGENT_DIR" "$WRAPPER_DIR"

if [[ ! -d "$TARGET_REPO" ]]; then
  echo "Repo target non trovato: $TARGET_REPO" >&2
  exit 1
fi

cp "$SCRIPT_DIR/vscode_maintenance_balanced.sh" "$BIN_DIR/vscode_maintenance_balanced.sh"
cp "$SCRIPT_DIR/merge_vscode_settings.py" "$BIN_DIR/merge_vscode_settings.py"
cp "$SCRIPT_DIR"/preset_*.settings.json "$PRESET_DIR/"

chmod +x "$BIN_DIR/vscode_maintenance_balanced.sh" "$BIN_DIR/merge_vscode_settings.py"

cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
"$BIN_DIR/vscode_maintenance_balanced.sh" --repo "$TARGET_REPO" --apply-presets
EOF
chmod +x "$WRAPPER_PATH"

cat > "$LAUNCH_AGENT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.vio.vscode-autopilot</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$BIN_DIR/vscode_maintenance_balanced.sh</string>
    <string>--repo</string>
    <string>$TARGET_REPO</string>
    <string>--apply-presets</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>86400</integer>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PATH"
launchctl enable "gui/$(id -u)/com.vio.vscode-autopilot" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/com.vio.vscode-autopilot" >/dev/null 2>&1 || true

printf "Autopilota installato.\n"
printf "Comando immediato: %s\n" "$WRAPPER_PATH"
printf "Repo target: %s\n" "$TARGET_REPO"

if [[ "$RUN_NOW" -eq 1 ]]; then
  "$WRAPPER_PATH"
fi
