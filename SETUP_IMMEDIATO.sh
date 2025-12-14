#!/bin/bash
# VIO Super AI - Setup Istantaneo
# Copia e incolla SOLO questa riga nel Terminal:
# curl -fsSL https://raw.githubusercontent.com/vio83/ai-scripts-elite/copilot/create-mac-system-monitor/SETUP_IMMEDIATO.sh | bash

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🚀 VIO Super AI - Setup Immediato"
echo "════════════════════════════════════════════════════════════"
echo ""

# Pulizia
cd ~/Desktop
rm -rf ai-scripts-elite

# Download
echo "→ Download codice..."
git clone -q -b copilot/create-mac-system-monitor https://github.com/vio83/ai-scripts-elite.git

# Setup
cd ai-scripts-elite
echo "→ Installazione dipendenze..."
pip3 install --user --quiet psutil Flask 2>/dev/null || true
mkdir -p ~/.vio_super_ai
chmod +x *.py *.sh 2>/dev/null

# Avvio dashboard
echo "→ Avvio dashboard iPhone..."
nohup python3 web_dashboard.py > ~/.vio_super_ai/dashboard.log 2>&1 &
sleep 3

# IP
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ PRONTO!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📱 SU IPHONE:"
echo "   Safari → http://$MAC_IP:5000"
echo "   Condividi → Aggiungi a Home"
echo ""
echo "🎨 Grafica ELITE sul Mac:"
echo ""

# Monitor ELITE
python3 mac_system_monitor_elite.py
