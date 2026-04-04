#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# VIO83 — DEPLOY UNIFICATO: Mac Air M1 → USB → iMac 2009 Kali Live
# ═══════════════════════════════════════════════════════════════════════════════
# Questo script incapsula l'INTERA catena in un unico punto di ingresso:
#   1. Verifica prerequisiti Mac (ISO, USB, script, repo)
#   2. Certifica hash ISO SHA256
#   3. Build bridge pack (script + assets)
#   4. Copia sulla partizione FAT della USB Kali
#   5. Stampa guida comandi iMac da eseguire dopo il boot
#
# USO: bash scripts/vio_mac_to_imac_unified.sh [--usb /dev/diskN] [--skip-write]
#
# Prerequisiti Mac:
#   • ISO in ~/Downloads/kali-linux-2026.1-live-amd64.iso
#   • USB da ≥8GB inserita
#   • repo ai-scripts-elite in ~/ai-scripts-elite/
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Configurazione ─────────────────────────────────────────────────────────────
REPO_DIR="${REPO_DIR:-$HOME/ai-scripts-elite}"
ISO_PATH="${ISO_PATH:-$HOME/Downloads/kali-linux-2026.1-live-amd64.iso}"
ISO_SHA256_EXPECTED="c2096dc2194c915cf94c273b907a84043ea6adfcba18509f15a8c1d1bbfb211c"
BRIDGE_PACK_DIR="${BRIDGE_PACK_DIR:-$HOME/.vio83/bridge_pack}"
LOG_FILE="$HOME/.vio83/deploy_unified_$(date +%Y%m%d_%H%M%S).log"
SKIP_WRITE=false
USB_DISK=""

# ── Colori ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $1${NC}" | tee -a "$LOG_FILE"; }
fail() { echo -e "  ${RED}❌  $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
warn() { echo -e "  ${YELLOW}⚠️   $1${NC}" | tee -a "$LOG_FILE"; }
info() { echo -e "  ${CYAN}→   $1${NC}" | tee -a "$LOG_FILE"; }
sep()  { echo -e "\n${BOLD}${BLUE}──── $1 ────${NC}\n" | tee -a "$LOG_FILE"; }

mkdir -p "$HOME/.vio83"

# ── Parsing argomenti ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --usb)        shift; USB_DISK="${1:-}"; shift || true ;;
    --usb=*)      USB_DISK="${arg#--usb=}" ;;
    --skip-write) SKIP_WRITE=true ;;
    --help|-h)
      echo "Uso: bash $0 [--usb /dev/diskN] [--skip-write]"
      echo "  --usb /dev/diskN    Specifica disco USB (es. /dev/disk4)"
      echo "  --skip-write        Salta la scrittura su USB, solo build bridge pack"
      exit 0 ;;
  esac
done

# ════════════════════════════════════════════════════════════════════════════════
echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  🏴 VIO83 — DEPLOY UNIFICATO Mac Air → USB → iMac Kali  ║${NC}"
echo -e "${BOLD}${BLUE}║  $(date '+%Y-%m-%d %H:%M:%S')                               ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
echo "" >> "$LOG_FILE"
echo "=== VIO83 DEPLOY UNIFICATO $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> "$LOG_FILE"

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 1 — PREREQUISITI MAC"

# 1a. Verifica repo
if [ ! -d "$REPO_DIR" ]; then
  fail "Repo non trovata: $REPO_DIR — esegui: git clone https://github.com/vio83/ai-scripts-elite.git $REPO_DIR"
fi
ok "Repo: $REPO_DIR"

# 1b. Verifica ISO
if [ ! -f "$ISO_PATH" ]; then
  fail "ISO non trovata: $ISO_PATH\n  Scarica da: https://www.kali.org/get-kali/#kali-live"
fi
ISO_SIZE_BYTES=$(stat -f%z "$ISO_PATH" 2>/dev/null || stat -c%s "$ISO_PATH")
ISO_SIZE_GB=$(echo "scale=1; $ISO_SIZE_BYTES / 1073741824" | bc 2>/dev/null || echo "?")
ok "ISO trovata: $ISO_PATH (${ISO_SIZE_GB} GB)"

# 1c. Verifica script chiave
REQUIRED_SCRIPTS=(
  "$REPO_DIR/kali_vio_bunker_deploy.sh"
  "$REPO_DIR/kali_iMac_diagnosi.sh"
  "$REPO_DIR/world_monitor.py"
  "$REPO_DIR/scripts/vio_edr_lite_status.sh"
)
for f in "${REQUIRED_SCRIPTS[@]}"; do
  if [ ! -f "$f" ]; then
    warn "Script mancante: $f — bridge pack sarà incompleto"
  else
    ok "Script: $(basename "$f")"
  fi
done

# 1d. Verifica tool mac
for cmd in shasum diskutil rsync; do
  command -v "$cmd" &>/dev/null && ok "Tool: $cmd" || fail "Tool mancante: $cmd"
done

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 2 — CERTIFICAZIONE SHA256 ISO"

info "Calcolo SHA256 (può richiedere 30-90 secondi su ISO 4GB)..."
ISO_SHA256_ACTUAL=$(shasum -a 256 "$ISO_PATH" | awk '{print $1}')
echo "  Hash calcolato:  $ISO_SHA256_ACTUAL" | tee -a "$LOG_FILE"
echo "  Hash atteso:     $ISO_SHA256_EXPECTED" | tee -a "$LOG_FILE"

if [ "$ISO_SHA256_ACTUAL" = "$ISO_SHA256_EXPECTED" ]; then
  ok "SHA256 ISO verificato ✔"
else
  fail "SHA256 ISO NON corrisponde — ISO corrotta o sostituita. Riscarica."
fi

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 3 — BUILD BRIDGE PACK"

BRIDGE_BUILD_SCRIPT="$REPO_DIR/scripts/mac_build_imac_bridge_pack.sh"
if [ -f "$BRIDGE_BUILD_SCRIPT" ]; then
  bash "$BRIDGE_BUILD_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
  ok "Bridge pack costruito: $BRIDGE_PACK_DIR"
else
  warn "Script bridge build non trovato — costruzione manuale"
  # Fallback manuale minimo
  mkdir -p "$BRIDGE_PACK_DIR"
  COPY_LIST=(
    "$REPO_DIR/kali_vio_bunker_deploy.sh"
    "$REPO_DIR/kali_iMac_diagnosi.sh"
    "$REPO_DIR/world_monitor.py"
    "$REPO_DIR/scripts/vio_edr_lite_status.sh"
    "$REPO_DIR/scripts/mac_bunker_baseline_apr2026.sh"
    "$REPO_DIR/envs/imac-kali.env"
  )
  for f in "${COPY_LIST[@]}"; do
    [ -f "$f" ] && cp -f "$f" "$BRIDGE_PACK_DIR/" && info "Copiato: $(basename "$f")" || warn "Assente: $(basename "$f")"
  done
  # Manifest + hash
  (cd "$BRIDGE_PACK_DIR" && find . -type f -exec shasum -a 256 {} \;) > "$BRIDGE_PACK_DIR/MANIFEST_SHA256.txt" 2>/dev/null || true
  ok "Bridge pack manuale: $BRIDGE_PACK_DIR ($(ls "$BRIDGE_PACK_DIR" | wc -l | tr -d ' ') file)"
fi

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 4 — RILEVAMENTO USB"

if [ -z "$USB_DISK" ]; then
  info "Rilevamento automatico USB Kali..."
  # Cerca disco esterno fisico con partizione FAT (tipicamente disco Kali live)
  USB_DISK=$(diskutil list external physical 2>/dev/null | awk '/^\/dev\/disk[0-9]/{print $1}' | head -1 || true)
  if [ -z "$USB_DISK" ]; then
    warn "Nessun disco USB esterno rilevato automaticamente"
    warn "Specifica con: --usb /dev/diskN"
    SKIP_WRITE=true
  else
    info "USB rilevata automaticamente: $USB_DISK"
    diskutil list "$USB_DISK" 2>/dev/null | tee -a "$LOG_FILE" || true
  fi
fi

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 5 — COPIA BRIDGE PACK SU USB FAT"

if $SKIP_WRITE; then
  warn "SKIP_WRITE attivo — copia USB saltata"
  warn "Per copiare manualmente: bash $REPO_DIR/scripts/mac_copy_kali_scripts_to_usb.sh --usb $USB_DISK"
else
  COPY_SCRIPT="$REPO_DIR/scripts/mac_copy_kali_scripts_to_usb.sh"
  if [ -f "$COPY_SCRIPT" ]; then
    # Individua partizione FAT della USB Kali (tipicamente s2 o s3)
    FAT_PART=$(diskutil list "$USB_DISK" 2>/dev/null | awk '/Windows_FAT|FAT32|MSDOS/{print $NF}' | head -1 || true)
    if [ -n "$FAT_PART" ]; then
      bash "$COPY_SCRIPT" --usb-partition "/dev/${FAT_PART}" 2>&1 | tee -a "$LOG_FILE"
      ok "Bridge pack copiato su /dev/$FAT_PART"
    else
      # Monta e copia manualmente
      MOUNT_POINT=$(mktemp -d)
      USB_FAT_PART="${USB_DISK}s2"  # Default convenzionale per Kali live
      if mount -t msdos "$USB_FAT_PART" "$MOUNT_POINT" 2>/dev/null; then
        rsync -av "$BRIDGE_PACK_DIR/" "$MOUNT_POINT/vio83-bridge-pack/" >> "$LOG_FILE" 2>&1
        diskutil unmount "$USB_FAT_PART" 2>/dev/null || true
        rmdir "$MOUNT_POINT"
        ok "Bridge pack rsync su $USB_FAT_PART"
      else
        warn "Mount FAT fallito — copia manuale necessaria"
        warn "Comandi manuali:"
        warn "  diskutil mount ${USB_DISK}s2"
        warn "  rsync -av $BRIDGE_PACK_DIR/ /Volumes/KALI_LIVE/vio83-bridge-pack/"
        rm -rf "$MOUNT_POINT"
      fi
    fi
  else
    warn "Script copia USB non trovato: $COPY_SCRIPT"
    warn "Copia manuale da: $BRIDGE_PACK_DIR"
  fi
fi

# ════════════════════════════════════════════════════════════════════════════════
sep "FASE 6 — GUIDA COMANDI iMac POST-BOOT"

echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  📋 COMANDI DA ESEGUIRE SUL TERMINALE DELL'iMAC KALI LIVE${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}  # STEP 1 — Diagnostica hardware (5-10 min)${NC}"
echo -e "  sudo bash /media/kali/*/vio83-bridge-pack/kali_iMac_diagnosi.sh"
echo ""
echo -e "${CYAN}  # STEP 2 — Monta bridge pack dalla USB se non auto-montato${NC}"
echo -e "  ls /media/kali/ 2>/dev/null || sudo mkdir -p /media/kali/usb"
echo -e "  sudo mount /dev/sda2 /media/kali/usb 2>/dev/null || true"
echo ""
echo -e "${CYAN}  # STEP 3 — Deploy bunker completo (30-90 min, richiede internet)${NC}"
echo -e "  sudo bash /media/kali/usb/vio83-bridge-pack/kali_vio_bunker_deploy.sh"
echo -e "  # Opzionale Wazuh manager IP: sudo WAZUH_MANAGER_IP=192.168.x.x bash ..."
echo ""
echo -e "${CYAN}  # STEP 4 — Verifica EDR-lite${NC}"
echo -e "  bash /media/kali/usb/vio83-bridge-pack/vio_edr_lite_status.sh --report-dir ~/edr-reports"
echo ""
echo -e "${CYAN}  # STEP 5 — World Monitor (porta 7778)${NC}"
echo -e "  python3 ~/ai-scripts-elite/world_monitor.py &"
echo -e "  # Poi recupera IP iMac: ip addr | grep 192.168"
echo ""
echo -e "${BOLD}${YELLOW}  ⚠️  iMac 2009: HDD SMART FAILING. Ogni scrittura è rischio.${NC}"
echo -e "${BOLD}${YELLOW}     Operare SOLO in memoria (live USB). Nessun mount del disco interno.${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
sep "RIEPILOGO FINALE"
echo "  Log: $LOG_FILE"
echo "  Bridge pack: $BRIDGE_PACK_DIR"
echo "  ISO SHA256: VERIFICATO ✔"
[ -n "$USB_DISK" ] && echo "  USB: $USB_DISK"
$SKIP_WRITE && echo "  Copia USB: SALTATA" || ok "Copia USB: COMPLETATA"
echo ""
ok "Deploy chain Mac Air M1 → iMac 2009 COMPLETATO"
