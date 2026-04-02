#!/bin/zsh
# Ripristino permanente automazione session workspace
# ⚠️ ESEGUI DA TERMINALE MAC FUORI DA VS CODE

set -euo pipefail

echo "=== VIO Session Workspace Automation Restoration ==="
echo ""

cd /Users/padronavio/ai-scripts-elite

# 1. Verifica Python script
echo "1️⃣ Verifica Python script..."
python3 -m py_compile scripts/vscode_session_workspaces/save_vscode_sessions.py && echo "   ✅ Python script OK"

# 2. Crea directory
echo "2️⃣ Crea directory..."
mkdir -p "$HOME/Library/Application Support/VIO/vscode-session-workspaces/{named,archive,bin}"
mkdir -p "$HOME/Library/Logs/VIO/vscode-session-workspaces"
echo "   ✅ Directory create"

# 3. Copia Python script
echo "3️⃣ Copia Python script..."
cp scripts/vscode_session_workspaces/save_vscode_sessions.py \
   "$HOME/Library/Application Support/VIO/vscode-session-workspaces/bin/"
chmod +x "$HOME/Library/Application Support/VIO/vscode-session-workspaces/bin/save_vscode_sessions.py"
echo "   ✅ Script copied"

# 4. Crea LaunchAgent plist
echo "4️⃣ Genera LaunchAgent plist..."
mkdir -p "$HOME/Library/LaunchAgents"

# Rileva Python Homebrew (preferred) o fallback a sistema
PYTHON_PATH=$( [[ -x /opt/homebrew/bin/python3 ]] && echo /opt/homebrew/bin/python3 || echo /usr/bin/python3 )
echo "   Python: $PYTHON_PATH ($($PYTHON_PATH --version 2>&1))"

cat > "$HOME/Library/LaunchAgents/com.vio.vscode-session-autosave.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vio.vscode-session-autosave</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>/Users/padronavio/Library/Application Support/VIO/vscode-session-workspaces/bin/save_vscode_sessions.py</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>/Users/padronavio/Library/Logs/VIO/vscode-session-workspaces/launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/padronavio/Library/Logs/VIO/vscode-session-workspaces/launchd.err.log</string>
</dict>
</plist>
EOF

chmod 644 "$HOME/Library/LaunchAgents/com.vio.vscode-session-autosave.plist"
echo "   ✅ LaunchAgent plist created"

# 5. Bootstrap LaunchAgent (bootout prima per pulire stato rotto)
echo "5️⃣ Bootstrap LaunchAgent..."
SVC_DOMAIN="gui/$(id -u)/com.vio.vscode-session-autosave"
launchctl bootout "$SVC_DOMAIN" 2>/dev/null && echo "   ♻️ Servizio precedente rimosso" || echo "   (nessun servizio precedente da rimuovere)"
sleep 1
launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/com.vio.vscode-session-autosave.plist"
echo "   ✅ LaunchAgent bootstrapped"

# 6. Kickstart e verifica status
echo "6️⃣ Avvio e verifica status..."
launchctl enable "$SVC_DOMAIN" 2>/dev/null || true
sleep 2
if launchctl list | grep -q "com.vio.vscode-session-autosave"; then
    LAUNCHD_STATUS=$(launchctl list | grep "com.vio.vscode-session-autosave")
    echo "   ✅ LaunchAgent ATTIVO: $LAUNCHD_STATUS"
else
    echo "   ⚠️ LaunchAgent non in lista, tentativo kickstart..."
    launchctl kickstart "$SVC_DOMAIN" 2>&1 || true
    sleep 2
    launchctl list | grep "com.vio.vscode-session-autosave" || echo "   ❌ Verifica log per errori"
fi

echo ""
echo "==================== VERIFICA FINALE ===================="
echo "📁 Directory snapshots:"
ls -la "$HOME/Library/Application Support/VIO/vscode-session-workspaces/named/" 2>/dev/null | tail -5
echo ""
echo "📋 Log output (ultimi 10 righe):"
if [[ -f "$HOME/Library/Logs/VIO/vscode-session-workspaces/launchd.out.log" ]]; then
    tail -n 10 "$HOME/Library/Logs/VIO/vscode-session-workspaces/launchd.out.log"
else
    echo "   (log non ancora creato - aspetta 5 secondi dal prossimo trigger)"
fi

echo ""
echo "✅ Setup completato. L'automazione è ATTIVA."
echo "📝 Nuovi snapshots verranno salvati ogni 5 minuti in:"
echo "   ~/Library/Application Support/VIO/vscode-session-workspaces/named/"
