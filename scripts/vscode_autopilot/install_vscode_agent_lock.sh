#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${VIO_AGENT_LOCK_APP_DIR:-$HOME/Library/Application Support/VIO/vscode-agent-lock}"
BIN_DIR="$APP_DIR/bin"
STATE_DIR="$APP_DIR/state"
LOG_DIR="${VIO_AGENT_LOCK_LOG_DIR:-$HOME/Library/Logs/VIO/vscode-agent-lock}"
USER_DIR="${VIO_VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"
SETTINGS_PATH="$USER_DIR/settings.json"
PROMPTS_DIR="$USER_DIR/prompts"
SOURCE_AGENT_PATH="$PROMPTS_DIR/ollama.agent.md"
BASELINE_SETTINGS="$STATE_DIR/settings.lock.json"
BASELINE_AGENT="$STATE_DIR/ollama.agent.md"
LAUNCH_AGENT_DIR="${VIO_LAUNCH_AGENT_DIR:-$HOME/Library/LaunchAgents}"
LAUNCH_AGENT_PATH="$LAUNCH_AGENT_DIR/com.vio.vscode-agent-lock.plist"
WRAPPER_DIR="${VIO_WRAPPER_DIR:-$HOME/.local/bin}"
WRAPPER_PATH="$WRAPPER_DIR/vio-vscode-agent-lock-now"
HARD_LOCK=0
RUN_NOW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hard-lock)
      HARD_LOCK=1
      shift
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

mkdir -p "$BIN_DIR" "$STATE_DIR" "$LOG_DIR" "$LAUNCH_AGENT_DIR" "$WRAPPER_DIR" "$PROMPTS_DIR"

if [[ ! -f "$SETTINGS_PATH" ]]; then
  echo "settings.json non trovato: $SETTINGS_PATH" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_AGENT_PATH" ]]; then
  echo "File agente non trovato: $SOURCE_AGENT_PATH" >&2
  exit 1
fi

cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vscode_agent_lock_enforcer.sh" "$BIN_DIR/vscode_agent_lock_enforcer.sh"
chmod +x "$BIN_DIR/vscode_agent_lock_enforcer.sh"

cp "$SOURCE_AGENT_PATH" "$BASELINE_AGENT"

/usr/bin/env python3 - "$SETTINGS_PATH" "$BASELINE_SETTINGS" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])

with settings_path.open("r", encoding="utf-8") as f:
    settings = json.load(f)

keys_to_freeze = [
    "chat.mcp.serverSampling",
    "chat.mcp.discovery.enabled",
    "chat.mcp.gallery.enabled",
    "chat.mcp.assisted.nuget.enabled",
    "chat.experimental.useSkillAdherencePrompt",
    "chat.useNestedAgentsMdFiles",
    "chat.includeReferencedInstructions",
    "chat.restoreLastPanelSession",
    "chat.customAgentInSubagent.enabled",
    "chat.viewProgressBadge.enabled",
    "chat.agentSessionProjection.enabled",
    "chat.exitAfterDelegation",
    "chat.tools.autoApprove",
    "inlineChat.enableV2",
    "inlineChat.notebookAgent",
    "inlineChat.renderMode",
    "ollamaAgent.mode",
    "ollamaAgent.host",
    "ollamaAgent.port",
    "ollamaAgent.provider",
    "ollamaAgent.systemPrompt",
    "github.copilot.chat.defaultModel"
]

baseline = {}
for key in keys_to_freeze:
    if key in settings:
        baseline[key] = settings[key]

# Non inserire fallback hardcodati per chiavi assenti: la baseline deve rispecchiare
# solo le impostazioni realmente presenti al momento dell'installazione.

if "ollamaAgent.mode" not in baseline:
    baseline["ollamaAgent.mode"] = "agent"
if "ollamaAgent.provider" not in baseline:
    baseline["ollamaAgent.provider"] = "ollama"
if "ollamaAgent.host" not in baseline:
    baseline["ollamaAgent.host"] = "localhost"
if "ollamaAgent.port" not in baseline:
    baseline["ollamaAgent.port"] = 11434

out_path.parent.mkdir(parents=True, exist_ok=True)
with out_path.open("w", encoding="utf-8") as f:
    json.dump(baseline, f, indent=2, ensure_ascii=True)
    f.write("\n")
PY

cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
"$BIN_DIR/vscode_agent_lock_enforcer.sh"
EOF
chmod +x "$WRAPPER_PATH"

cat > "$LAUNCH_AGENT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.vio.vscode-agent-lock</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$BIN_DIR/vscode_agent_lock_enforcer.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>300</integer>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/launchd.err.log</string>
</dict>
</plist>
EOF

if command -v launchctl >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
  launchctl enable "gui/$(id -u)/com.vio.vscode-agent-lock" >/dev/null 2>&1 || true
  launchctl kickstart -k "gui/$(id -u)/com.vio.vscode-agent-lock" >/dev/null 2>&1 || true
fi

if [[ "$RUN_NOW" -eq 1 ]]; then
  "$BIN_DIR/vscode_agent_lock_enforcer.sh"
fi

if [[ "$HARD_LOCK" -eq 1 ]]; then
  # Hard-lock SOLO sui file baseline — mai sui file live che VS Code deve poter scrivere.
  # settings.json e ollama.agent.md live rimangono scrivibili da VS Code e dall'enforcer.
  chflags nouchg "$BASELINE_SETTINGS" "$BASELINE_AGENT" >/dev/null 2>&1 || true
  chflags uchg "$BASELINE_SETTINGS" "$BASELINE_AGENT"
fi

echo "Lock agente VS Code installato."
echo "Enforcer: $BIN_DIR/vscode_agent_lock_enforcer.sh"
echo "Wrapper: $WRAPPER_PATH"
echo "LaunchAgent: $LAUNCH_AGENT_PATH"
echo "Baseline settings: $BASELINE_SETTINGS"
echo "Baseline agente: $BASELINE_AGENT"
if [[ "$HARD_LOCK" -eq 1 ]]; then
  echo "Hard-lock attivo sui baseline (chflags uchg su settings.lock.json e ollama.agent.md baseline)."
fi
