#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/Library/Application Support/VIO/vscode-session-workspaces"
BIN_DIR="$APP_DIR/bin"
NAMED_DIR="$APP_DIR/named"
ARCHIVE_DIR="$APP_DIR/archive"
LOG_DIR="$HOME/Library/Logs/VIO/vscode-session-workspaces"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PATH="$LAUNCH_AGENT_DIR/com.vio.vscode-session-autosave.plist"
WRAPPER_DIR="$HOME/.local/bin"
WRAPPER_PATH="$WRAPPER_DIR/vio-vscode-session-save-now"
INTERVAL="300"
RUN_NOW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      INTERVAL="$2"
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

mkdir -p "$BIN_DIR" "$NAMED_DIR" "$ARCHIVE_DIR" "$LOG_DIR" "$LAUNCH_AGENT_DIR" "$WRAPPER_DIR"

cp "$SCRIPT_DIR/save_vscode_sessions.py" "$BIN_DIR/save_vscode_sessions.py"
chmod +x "$BIN_DIR/save_vscode_sessions.py"

cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
/usr/bin/python3 "$BIN_DIR/save_vscode_sessions.py" "\$@"
EOF
chmod +x "$WRAPPER_PATH"

cat > "$LAUNCH_AGENT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.vio.vscode-session-autosave</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>$BIN_DIR/save_vscode_sessions.py</string>
    <string>--only-latest</string>
    <string>--output-dir</string>
    <string>$NAMED_DIR</string>
    <string>--archive-dir</string>
    <string>$ARCHIVE_DIR</string>
    <string>--index-path</string>
    <string>$APP_DIR/index.json</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>$INTERVAL</integer>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PATH"
launchctl enable "gui/$(id -u)/com.vio.vscode-session-autosave" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/com.vio.vscode-session-autosave" >/dev/null 2>&1 || true

printf "Autosave sessioni VS Code installato.\n"
printf "Comando immediato: %s\n" "$WRAPPER_PATH"
printf "Workspace nominati: %s\n" "$NAMED_DIR"
printf "Archivio snapshot: %s\n" "$ARCHIVE_DIR"

if [[ "$RUN_NOW" -eq 1 ]]; then
  "$WRAPPER_PATH" --only-latest --output-dir "$NAMED_DIR" --archive-dir "$ARCHIVE_DIR" --index-path "$APP_DIR/index.json"
fi
