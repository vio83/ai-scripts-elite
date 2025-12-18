#!/bin/bash
# VIO Super AI - Setup Auto-Start Permanente
# Configura avvio automatico della dashboard

set -e

COLORS_RED='\033[0;31m'
COLORS_GREEN='\033[0;32m'
COLORS_YELLOW='\033[1;33m'
COLORS_BLUE='\033[0;34m'
COLORS_CYAN='\033[0;36m'
COLORS_NC='\033[0m'

echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  VIO Super AI - Setup Auto-Start Permanente                    ${COLORS_CYAN}║${COLORS_NC}"
echo -e "${COLORS_CYAN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create LaunchAgent for web dashboard
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"

PLIST_FILE="$LAUNCH_AGENTS_DIR/com.viosuperai.dashboard.plist"

echo -e "${COLORS_BLUE}→${COLORS_NC} Creazione LaunchAgent per dashboard web..."

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.viosuperai.dashboard</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>$SCRIPT_DIR/web_dashboard.py</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$HOME/.vio_super_ai/dashboard.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/.vio_super_ai/dashboard_error.log</string>
    
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
</dict>
</plist>
EOF

echo -e "${COLORS_GREEN}✓ LaunchAgent creato${COLORS_NC}"

# Unload if already loaded
launchctl unload "$PLIST_FILE" 2>/dev/null || true

# Load the LaunchAgent
echo -e "${COLORS_BLUE}→${COLORS_NC} Caricamento LaunchAgent..."
launchctl load "$PLIST_FILE"
echo -e "${COLORS_GREEN}✓ LaunchAgent caricato${COLORS_NC}"

# Wait a moment for service to start
sleep 2

# Get Mac IP
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo -e "${COLORS_GREEN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_GREEN}║${COLORS_NC}  Setup Auto-Start Completato! 🎉                               ${COLORS_GREEN}║${COLORS_NC}"
echo -e "${COLORS_GREEN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}✅ Dashboard web ora si avvia AUTOMATICAMENTE al login!${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}📱 Per accedere da iPhone:${COLORS_NC}"
if [ -n "$MAC_IP" ]; then
    echo -e "   ${COLORS_YELLOW}http://$MAC_IP:5000${COLORS_NC}"
else
    echo -e "   ${COLORS_YELLOW}http://TUO_IP_MAC:5000${COLORS_NC}"
fi
echo ""
echo -e "${COLORS_CYAN}📊 Verifica servizio:${COLORS_NC}"
echo -e "   ${COLORS_YELLOW}./check_status.sh${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}🔄 Per fermare:${COLORS_NC}"
echo -e "   ${COLORS_YELLOW}launchctl unload $PLIST_FILE${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}📖 Log file:${COLORS_NC}"
echo -e "   ${COLORS_YELLOW}~/.vio_super_ai/dashboard.log${COLORS_NC}"
echo ""
