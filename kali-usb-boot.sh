#!/bin/bash
# ============================================================
# KALI LINUX USB LIVE BOOT — Mac Air → iMac 2009
# Esegui su: Mac Air (padronavio)
# Obiettivo: Creare USB avviabile Kali per iMac
# ============================================================

set -e
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ISO_URL="https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-live-amd64.iso"
ISO_NAME="kali-linux-light-2024.1-live-amd64.iso"
ISO_PATH="$HOME/Downloads/$ISO_NAME"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   🐉 KALI LINUX USB CREATOR — Mac Air → iMac 2009      ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# ── STEP 1: Download ISO ──────────────────────────────────
echo -e "${BOLD}STEP 1 — Download Kali Linux Light ISO${NC}"
echo "Dimensione: ~420 MB | Versione: 2024.1 (amd64)"
echo ""

if [ -f "$ISO_PATH" ]; then
    echo -e "${GREEN}✅ ISO già presente: $ISO_PATH${NC}"
    echo "   Salto download."
else
    echo "📥 Download in corso..."
    curl -L --progress-bar -o "$ISO_PATH" "$ISO_URL"
    echo -e "${GREEN}✅ Download completato: $ISO_PATH${NC}"
fi

echo ""

# ── STEP 2: Identifica USB ────────────────────────────────
echo -e "${BOLD}STEP 2 — Inserisci USB (minimo 2 GB)${NC}"
echo ""
echo -e "${YELLOW}⚠️  TUTTI I DATI SU USB VERRANNO CANCELLATI${NC}"
echo ""
echo "Collega la USB nel Mac Air, poi premi ENTER..."
read

echo ""
echo "Dischi rilevati:"
echo "────────────────────────────────────────"
diskutil list
echo "────────────────────────────────────────"
echo ""
echo "Identifica il numero del disco USB (es: 2 → /dev/disk2)"
read -p "Numero disco USB: " DISK_NUM

DISK="/dev/disk${DISK_NUM}"
RAW_DISK="/dev/rdisk${DISK_NUM}"

# Verifica che esista
if ! diskutil info "$DISK" &>/dev/null; then
    echo -e "${RED}❌ Disco $DISK non trovato. Ricontrolla.${NC}"
    exit 1
fi

# Mostra info disco scelto
echo ""
echo "Disco selezionato:"
diskutil info "$DISK" | grep -E "Device|Disk Size|Media Name|Removable"
echo ""

# Verifica che sia removibile (sicurezza)
REMOVABLE=$(diskutil info "$DISK" | grep "Removable Media" | awk '{print $NF}')
if [ "$REMOVABLE" != "Yes" ] && [ "$REMOVABLE" != "Removable" ]; then
    echo -e "${RED}❌ STOP: $DISK non sembra un disco rimovibile.${NC}"
    echo "   Controlla bene di non aver scelto il disco di sistema."
    exit 1
fi

echo -e "${RED}⚠️  ULTIMA CONFERMA — CANCELLA TUTTO SU $DISK${NC}"
read -p "Scrivi YES per confermare: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "❌ Annullato."
    exit 1
fi

echo ""

# ── STEP 3: Unmount USB ──────────────────────────────────
echo -e "${BOLD}STEP 3 — Unmount USB${NC}"
diskutil unmountDisk "$DISK" 2>/dev/null || true
echo -e "${GREEN}✅ USB smontata${NC}"
echo ""

# ── STEP 4: Scrivi ISO ───────────────────────────────────
echo -e "${BOLD}STEP 4 — Scrittura Kali su USB (10-15 min)${NC}"
echo "Comando: sudo dd if=$ISO_PATH of=$RAW_DISK bs=1m"
echo ""
echo -e "${YELLOW}Inserisci password admin Mac Air:${NC}"

echo "   → Sembrerà bloccato: è normale. Premi Ctrl+T per progress."
sudo dd if="$ISO_PATH" of="$RAW_DISK" bs=1m

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ USB Kali Linux pronta!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"

# ── STEP 5: Eject ────────────────────────────────────────
echo ""
echo -e "${BOLD}STEP 5 — Eject USB${NC}"
diskutil eject "$DISK" && echo -e "${GREEN}✅ USB espulsa${NC}"

# ── ISTRUZIONI IMAC ─────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   📋 ISTRUZIONI BOOT iMac 2009                         ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}1.${NC} Inserisci USB nel iMac"
echo -e "${BOLD}2.${NC} Spegni iMac completamente"
echo -e "${BOLD}3.${NC} Accendi iMac e tieni premuto: ${YELLOW}Option (⌥)${NC}"
echo -e "   → Mantieni premuto finché appare lo schermo boot picker"
echo ""
echo -e "${BOLD}4.${NC} Schermo boot picker → Vedrai le opzioni:"
echo -e "   ${CYAN}[Macintosh HD]${NC}  [EFI Boot / USB Kali]${NC}"
echo ""
echo -e "${BOLD}5.${NC} Seleziona USB (frecce ← →) e premi ${YELLOW}ENTER${NC}"
echo ""
echo -e "${BOLD}6.${NC} Menu Kali:"
echo -e "   Scegli: ${CYAN}Live system (amd64)${NC}"
echo ""
echo -e "${BOLD}7.${NC} ${GREEN}✅ Kali Linux carico in RAM — disco iMac intoccato!${NC}"
echo ""
echo -e "${YELLOW}NOTE:${NC}"
echo "  • Credenziali default Kali Live: root / toor"
echo "  • Niente viene scritto sul disco iMac"
echo "  • Per uscire: spegni iMac, rimuovi USB → torna macOS"
echo ""
echo -e "${RED}⚠️  PROMEMORIA: Disco iMac S.M.A.R.T. FAILING${NC}"
echo "    Non installare Kali permanente finché non sostituisci HDD"
echo ""
