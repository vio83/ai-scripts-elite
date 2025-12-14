#!/bin/bash
# VIO Super AI - Check Status
# Verifica stato dei servizi

COLORS_GREEN='\033[0;32m'
COLORS_RED='\033[0;31m'
COLORS_CYAN='\033[0;36m'
COLORS_NC='\033[0m'

echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  VIO Super AI - Status Check                                      ${COLORS_CYAN}║${COLORS_NC}"
echo -e "${COLORS_CYAN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""

# Check if web dashboard is running
if pgrep -f "web_dashboard.py" > /dev/null; then
    PID=$(pgrep -f "web_dashboard.py")
    PORT=$(lsof -nP -iTCP:5000 -sTCP:LISTEN 2>/dev/null | grep LISTEN | wc -l)
    if [ "$PORT" -gt 0 ]; then
        echo -e "${COLORS_GREEN}✅ Web Dashboard: RUNNING${COLORS_NC} (PID: $PID, Port: 5000)"
    else
        echo -e "${COLORS_RED}⚠️  Web Dashboard: RUNNING but port 5000 not open${COLORS_NC}"
    fi
else
    echo -e "${COLORS_RED}❌ Web Dashboard: NOT RUNNING${COLORS_NC}"
fi

# Check LaunchAgent
PLIST_FILE="$HOME/Library/LaunchAgents/com.viosuperai.dashboard.plist"
if [ -f "$PLIST_FILE" ]; then
    if launchctl list | grep "com.viosuperai.dashboard" > /dev/null; then
        echo -e "${COLORS_GREEN}✅ LaunchAgent: LOADED${COLORS_NC} (auto-start attivo)"
    else
        echo -e "${COLORS_RED}⚠️  LaunchAgent: FOUND but not loaded${COLORS_NC}"
    fi
else
    echo -e "${COLORS_RED}❌ LaunchAgent: NOT CONFIGURED${COLORS_NC}"
fi

# Check email configuration
EMAIL_CONFIG="$HOME/.vio_super_ai/email_config.json"
if [ -f "$EMAIL_CONFIG" ]; then
    if grep -q '"enabled": *true' "$EMAIL_CONFIG"; then
        echo -e "${COLORS_GREEN}✅ Email Notifications: ENABLED${COLORS_NC}"
    else
        echo -e "${COLORS_RED}⚠️  Email Notifications: DISABLED${COLORS_NC}"
    fi
else
    echo -e "${COLORS_RED}❌ Email Configuration: NOT FOUND${COLORS_NC}"
fi

# Show Mac IP
echo ""
echo -e "${COLORS_CYAN}📱 iPhone Access URL:${COLORS_NC}"
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if [ -n "$MAC_IP" ]; then
    echo -e "   ${COLORS_GREEN}http://$MAC_IP:5000${COLORS_NC}"
else
    echo -e "   ${COLORS_RED}Could not detect IP${COLORS_NC}"
fi

# Check log files
echo ""
echo -e "${COLORS_CYAN}📊 Log Files:${COLORS_NC}"
if [ -f ~/.vio_super_ai/dashboard.log ]; then
    LOG_SIZE=$(du -h ~/.vio_super_ai/dashboard.log | cut -f1)
    echo -e "   Dashboard: ${LOG_SIZE} (~/.vio_super_ai/dashboard.log)"
fi

echo ""
