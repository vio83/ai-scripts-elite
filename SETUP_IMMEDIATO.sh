#!/bin/bash
# VIO Super AI - Setup Istantaneo
# Copia e incolla SOLO questa riga nel Terminal:
# curl -fsSL https://raw.githubusercontent.com/vio83/ai-scripts-elite/copilot/create-mac-system-monitor/SETUP_IMMEDIATO.sh | bash

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🚀 VIO Super AI - Setup Immediato"
echo "════════════════════════════════════════════════════════════"
echo ""

# Pulizia
cd ~/Desktop
rm -rf ai-scripts-elite 2>/dev/null || true

# Download
echo "→ Download codice..."
git clone -q -b copilot/create-mac-system-monitor https://github.com/vio83/ai-scripts-elite.git 2>&1 || {
    echo "❌ Errore download. Verifica connessione."
    exit 1
}

# Setup
cd ai-scripts-elite
echo "→ Installazione dipendenze..."
pip3 install --user --quiet psutil Flask 2>&1 || {
    echo "⚠️  Pip3 non trovato, provo python3 -m pip..."
    python3 -m pip install --user --quiet psutil Flask 2>&1 || true
}
mkdir -p ~/.vio_super_ai
chmod +x *.py *.sh 2>/dev/null || true

# Trova IP - prova vari metodi
echo "→ Ricerca indirizzo IP..."
MAC_IP=""

# Metodo 1: ifconfig
if command -v ifconfig &> /dev/null; then
    MAC_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
fi

# Metodo 2: ip (Linux)
if [ -z "$MAC_IP" ] && command -v ip &> /dev/null; then
    MAC_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)
fi

# Metodo 3: networksetup (macOS)
if [ -z "$MAC_IP" ] && command -v networksetup &> /dev/null; then
    for interface in $(networksetup -listallhardwareports | awk '/Device:/ {print $2}'); do
        IP=$(ipconfig getifaddr "$interface" 2>/dev/null)
        if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
            MAC_IP="$IP"
            break
        fi
    done
fi

# Fallback
if [ -z "$MAC_IP" ]; then
    MAC_IP="TUO_IP_MAC"
    echo "⚠️  Non ho trovato IP automaticamente"
fi

# Avvio dashboard
echo "→ Avvio dashboard iPhone..."
nohup python3 web_dashboard.py > ~/.vio_super_ai/dashboard.log 2>&1 &
DASHBOARD_PID=$!
sleep 3

# Verifica che sia partito
if ps -p $DASHBOARD_PID > /dev/null 2>&1; then
    echo "✅ Dashboard avviata!"
else
    echo "⚠️  Dashboard potrebbe avere problemi. Controlla log:"
    echo "   cat ~/.vio_super_ai/dashboard.log"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ PRONTO!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📱 SU IPHONE - APRI SAFARI E VAI A:"
echo ""
echo "   http://$MAC_IP:5000"
echo ""
echo "   Poi: Condividi → Aggiungi a Home"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🎨 Avvio grafica ELITE sul Mac..."
echo ""
sleep 2

# Monitor ELITE
python3 mac_system_monitor_elite.py
