#!/bin/bash
# VIO Super AI - Stop All Services
# Ferma tutti i servizi attivi

COLORS_RED='\033[0;31m'
COLORS_YELLOW='\033[1;33m'
COLORS_NC='\033[0m'

echo -e "${COLORS_YELLOW}🛑 VIO Super AI - Arresto Servizi${COLORS_NC}"
echo ""

# Stop LaunchAgent if active
PLIST_FILE="$HOME/Library/LaunchAgents/com.viosuperai.dashboard.plist"
if [ -f "$PLIST_FILE" ]; then
    echo "→ Arresto LaunchAgent..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    echo "✓ LaunchAgent fermato"
fi

# Stop dashboard if running from run_permanent.sh
if [ -f ~/.vio_super_ai/dashboard.pid ]; then
    PID=$(cat ~/.vio_super_ai/dashboard.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "→ Arresto dashboard (PID: $PID)..."
        kill $PID 2>/dev/null || true
        echo "✓ Dashboard fermata"
    fi
    rm ~/.vio_super_ai/dashboard.pid
fi

# Kill any remaining Python processes running web_dashboard
pkill -f "web_dashboard.py" 2>/dev/null || true

echo ""
echo -e "${COLORS_RED}✅ Tutti i servizi sono stati fermati${COLORS_NC}"
echo ""
