#!/bin/bash
# VIO Super AI - INSTALLAZIONE ULTRA RAPIDA
# Tutto in 1 comando - Pronto in 2 minuti!

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🚀 VIO SUPER AI - INSTALLAZIONE RAPIDA (2 minuti)      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Installa dipendenze
echo "→ Installazione dipendenze..."
pip3 install --user --quiet psutil Flask 2>/dev/null || pip3 install --quiet psutil Flask
echo "✅ Dipendenze installate"

# 2. Rendi eseguibili
chmod +x *.py *.sh 2>/dev/null

# 3. Crea config email (vuota per ora)
mkdir -p ~/.vio_super_ai
if [ ! -f ~/.vio_super_ai/email_config.json ]; then
    echo '{"enabled":false}' > ~/.vio_super_ai/email_config.json
fi

# 4. Avvia dashboard SUBITO
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
nohup python3 "$SCRIPT_DIR/web_dashboard.py" > ~/.vio_super_ai/dashboard.log 2>&1 &
echo "✅ Dashboard avviata!"

# 5. Aspetta 2 secondi
sleep 2

# 6. Mostra IP
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ PRONTO! Dashboard attiva!                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 SU IPHONE APRI SAFARI E VAI A:"
echo ""
echo "   🔗 http://$MAC_IP:5000"
echo ""
echo "   Poi: Condividi → Aggiungi a Home"
echo ""
echo "📝 SALVA QUESTO IP PER DOPO:"
echo "   $MAC_IP"
echo ""
echo "✅ ORA PUOI PARTIRE! Il servizio resta attivo!"
echo ""
