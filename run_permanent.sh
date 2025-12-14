#!/bin/bash
# VIO Super AI - Run Permanent Services
# Avvia tutti i servizi in background

COLORS_GREEN='\033[0;32m'
COLORS_CYAN='\033[0;36m'
COLORS_NC='\033[0m'

echo -e "${COLORS_CYAN}🚀 VIO Super AI - Avvio Servizi Permanenti${COLORS_NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create log directory
mkdir -p ~/.vio_super_ai

# Start web dashboard in background
echo -e "${COLORS_GREEN}→${COLORS_NC} Avvio dashboard web..."
nohup python3 "$SCRIPT_DIR/web_dashboard.py" > ~/.vio_super_ai/dashboard.log 2>&1 &
DASHBOARD_PID=$!
echo $DASHBOARD_PID > ~/.vio_super_ai/dashboard.pid
echo -e "${COLORS_GREEN}✓${COLORS_NC} Dashboard avviata (PID: $DASHBOARD_PID)"

# Get Mac IP
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo -e "${COLORS_GREEN}✅ Servizi avviati con successo!${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}📱 Accedi da iPhone:${COLORS_NC}"
if [ -n "$MAC_IP" ]; then
    echo -e "   http://$MAC_IP:5000"
else
    echo -e "   http://TUO_IP_MAC:5000"
fi
echo ""
echo -e "${COLORS_CYAN}📊 Verifica status:${COLORS_NC}"
echo -e "   ./check_status.sh"
echo ""
echo -e "${COLORS_CYAN}🛑 Per fermare:${COLORS_NC}"
echo -e "   ./stop_all.sh"
echo ""
