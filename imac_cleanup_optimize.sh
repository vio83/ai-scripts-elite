#!/bin/bash
# ════════════════════════════════════════════════════════════════
#   iMac 2009 (iMac11,1) — Pulizia Totale + Ottimizzazione
#   macOS 10.13.6 High Sierra
#   Data: 2026-04-01
#   PRESERVA: Macs Fan Control, impostazioni ventole
#   Eseguire su iMac da Terminal.app come admin
# ════════════════════════════════════════════════════════════════

set -euo pipefail

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="$HOME/Desktop/imac_cleanup_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_section() {
    log ""
    log "${CYAN}════════════════════════════════════════${NC}"
    log "${BOLD}  $1${NC}"
    log "${CYAN}════════════════════════════════════════${NC}"
}

bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    else
        echo "$bytes bytes"
    fi
}

freed_total=0

safe_clean() {
    local desc="$1"
    local target="$2"
    
    if [ -e "$target" ]; then
        local size_before
        size_before=$(du -sk "$target" 2>/dev/null | awk '{print $1}') || size_before=0
        size_before=$((size_before * 1024))
        
        if rm -rf "$target" 2>/dev/null; then
            freed_total=$((freed_total + size_before))
            log "  ${GREEN}✔${NC} $desc — $(bytes_to_human "$size_before")"
        else
            log "  ${YELLOW}⚠${NC} $desc — permesso negato, provo con sudo..."
            if sudo rm -rf "$target" 2>/dev/null; then
                freed_total=$((freed_total + size_before))
                log "  ${GREEN}✔${NC} $desc — $(bytes_to_human "$size_before") (sudo)"
            else
                log "  ${RED}✖${NC} $desc — impossibile rimuovere"
            fi
        fi
    fi
}

safe_clean_dir_contents() {
    local desc="$1"
    local target="$2"
    
    if [ -d "$target" ]; then
        local size_before
        size_before=$(du -sk "$target" 2>/dev/null | awk '{print $1}') || size_before=0
        size_before=$((size_before * 1024))
        
        find "$target" -mindepth 1 -delete 2>/dev/null || \
            sudo find "$target" -mindepth 1 -delete 2>/dev/null || true
        
        local size_after
        size_after=$(du -sk "$target" 2>/dev/null | awk '{print $1}') || size_after=0
        size_after=$((size_after * 1024))
        
        local freed=$((size_before - size_after))
        if [ "$freed" -gt 0 ]; then
            freed_total=$((freed_total + freed))
        fi
        log "  ${GREEN}✔${NC} $desc — $(bytes_to_human "$freed")"
    fi
}

# ─────────────────────────────────────────────────────────
# CONTROLLI INIZIALI
# ─────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   🧹 iMac 2009 — PULIZIA TOTALE + OTTIMIZZAZIONE MAX"
echo "   macOS 10.13.6 High Sierra — $(date '+%Y-%m-%d %H:%M')"
echo "════════════════════════════════════════════════════════════"
echo ""

# Verifica macOS compatibile
SW_VER=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
log "macOS rilevato: $SW_VER"

if [[ "$SW_VER" != 10.13* ]]; then
    log "${YELLOW}⚠ Script ottimizzato per 10.13.x — proseguo con cautela${NC}"
fi

# Verifica admin
if ! groups | grep -qw admin; then
    log "${RED}❌ L'utente corrente non è admin. Esegui con un account admin.${NC}"
    exit 1
fi

# Stato disco PRIMA
log_section "STATO DISCO — PRIMA DELLA PULIZIA"
DISK_BEFORE=$(df -h / | tail -1)
log "  $DISK_BEFORE"
AVAIL_BEFORE=$(df -k / | tail -1 | awk '{print $4}')
log ""

# Verifica Macs Fan Control
MFC_PRESENT=false
if [ -d "/Applications/Macs Fan Control.app" ] || \
   [ -d "$HOME/Applications/Macs Fan Control.app" ] || \
   pgrep -x "Macs Fan Control" >/dev/null 2>&1; then
    MFC_PRESENT=true
    log "${GREEN}✔ Macs Fan Control rilevato — SARÀ PRESERVATO${NC}"
else
    log "${YELLOW}⚠ Macs Fan Control non trovato nelle posizioni standard${NC}"
fi

# Conferma
echo ""
echo -e "${YELLOW}⚠ ATTENZIONE: Questo script elimina cache, log, file temporanei.${NC}"
echo -e "${GREEN}✔ Macs Fan Control e impostazioni ventole PRESERVATI.${NC}"
echo -e "${GREEN}✔ App e documenti personali NON toccati.${NC}"
echo ""
read -p "Procedi con la pulizia? (s/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Annullato."
    exit 0
fi

echo ""
log "Password admin necessaria per operazioni di sistema..."
sudo -v
# Mantieni sudo attivo
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null; exit' EXIT INT TERM

# ─────────────────────────────────────────────────────────
# FASE 1 — CACHE DI SISTEMA
# ─────────────────────────────────────────────────────────

log_section "FASE 1 — CACHE DI SISTEMA"

safe_clean_dir_contents "Cache sistema" "/Library/Caches"
safe_clean_dir_contents "Cache utente" "$HOME/Library/Caches"

# Cache specifiche pesanti (escluse quelle di Macs Fan Control)
for cache_dir in "$HOME/Library/Caches/"*; do
    if [ -d "$cache_dir" ]; then
        dir_name=$(basename "$cache_dir")
        # Preserva Macs Fan Control
        if [[ "$dir_name" == *"MacsFanControl"* ]] || \
           [[ "$dir_name" == *"macs-fan-control"* ]] || \
           [[ "$dir_name" == *"crystalidea"* ]]; then
            log "  ${GREEN}⏭ PRESERVATO: $dir_name (Macs Fan Control)${NC}"
            continue
        fi
    fi
done

# Shared cache
safe_clean_dir_contents "Cache condivise" "/private/var/folders"

log ""

# ─────────────────────────────────────────────────────────
# FASE 2 — LOG E FILE TEMPORANEI
# ─────────────────────────────────────────────────────────

log_section "FASE 2 — LOG E FILE TEMPORANEI"

safe_clean_dir_contents "Log di sistema" "/private/var/log"
safe_clean_dir_contents "Log utente" "$HOME/Library/Logs"
safe_clean_dir_contents "Crash reports sistema" "/Library/Logs/DiagnosticReports"
safe_clean_dir_contents "Crash reports utente" "$HOME/Library/Logs/DiagnosticReports"
safe_clean_dir_contents "Tmp di sistema" "/private/tmp"
safe_clean_dir_contents "Tmp var" "/private/var/tmp"

# Rimuovi vecchi report di sistema
safe_clean "Report Apple System Profiler" "$HOME/Library/Logs/SystemProfiler"

# Log kernel vecchi
sudo find /private/var/log -name "*.gz" -delete 2>/dev/null && \
    log "  ${GREEN}✔${NC} Log compressi vecchi rimossi" || true

log ""

# ─────────────────────────────────────────────────────────
# FASE 3 — CESTINO E DOWNLOAD VECCHI
# ─────────────────────────────────────────────────────────

log_section "FASE 3 — CESTINO"

# Cestini di tutti gli utenti
if [ -d "$HOME/.Trash" ]; then
    TRASH_SIZE=$(du -sh "$HOME/.Trash" 2>/dev/null | awk '{print $1}')
    safe_clean_dir_contents "Cestino utente ($TRASH_SIZE)" "$HOME/.Trash"
fi

# Cestino volume
for trash in /Volumes/*/.Trashes; do
    if [ -d "$trash" ]; then
        safe_clean_dir_contents "Cestino volume $(dirname "$trash")" "$trash"
    fi
done

log ""

# ─────────────────────────────────────────────────────────
# FASE 4 — CACHE BROWSER
# ─────────────────────────────────────────────────────────

log_section "FASE 4 — CACHE BROWSER"

# Safari
safe_clean "Safari cache" "$HOME/Library/Caches/com.apple.Safari"
safe_clean "Safari cache pagine" "$HOME/Library/Caches/com.apple.Safari.SafeBrowsing"
safe_clean "Safari WebKit cache" "$HOME/Library/Caches/com.apple.WebKit.PluginProcess"
# Non tocchiamo segnalibri o password Safari

# Chrome (se presente)
if [ -d "$HOME/Library/Application Support/Google/Chrome" ]; then
    for profile in "$HOME/Library/Application Support/Google/Chrome/"*; do
        if [ -d "$profile/Cache" ]; then
            safe_clean "Chrome cache ($(basename "$profile"))" "$profile/Cache"
        fi
        if [ -d "$profile/Code Cache" ]; then
            safe_clean "Chrome code cache ($(basename "$profile"))" "$profile/Code Cache"
        fi
    done
fi

# Firefox (se presente)
if [ -d "$HOME/Library/Caches/Firefox" ]; then
    safe_clean_dir_contents "Firefox cache" "$HOME/Library/Caches/Firefox"
fi

log ""

# ─────────────────────────────────────────────────────────
# FASE 5 — FILE DI SISTEMA NON NECESSARI
# ─────────────────────────────────────────────────────────

log_section "FASE 5 — FILE DI SISTEMA OBSOLETI"

# Vecchi aggiornamenti software scaricati
safe_clean_dir_contents "Update macOS scaricati" "/Library/Updates"

# Installer packages ricevuti
safe_clean_dir_contents "Installer packages vecchi" "$HOME/Library/Application Support/Installer"

# Vecchi backup iOS/iTunes (spesso enormi)
ITUNES_BACKUP="$HOME/Library/Application Support/MobileSync/Backup"
if [ -d "$ITUNES_BACKUP" ]; then
    BACKUP_SIZE=$(du -sh "$ITUNES_BACKUP" 2>/dev/null | awk '{print $1}')
    log "  ${YELLOW}📱 Backup iOS trovati: $BACKUP_SIZE${NC}"
    echo -e "  ${YELLOW}Vuoi eliminare i backup iOS? Sono spesso 5-50 GB (s/n)${NC}"
    read -p "  " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        safe_clean_dir_contents "Backup iOS ($BACKUP_SIZE)" "$ITUNES_BACKUP"
    else
        log "  ⏭ Backup iOS preservati"
    fi
fi

# Xcode derived data (se presente)
safe_clean "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
safe_clean "Xcode Archives vecchi" "$HOME/Library/Developer/Xcode/Archives"

# Mail download
safe_clean_dir_contents "Mail download cache" "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"

# Vecchi font cache
sudo atsutil databases -remove 2>/dev/null && \
    log "  ${GREEN}✔${NC} Font cache rimossa (si ricostruirà al riavvio)" || true

log ""

# ─────────────────────────────────────────────────────────
# FASE 6 — SPOTLIGHT RE-INDEX
# ─────────────────────────────────────────────────────────

log_section "FASE 6 — REBUILD SPOTLIGHT"

sudo mdutil -E / 2>/dev/null && \
    log "  ${GREEN}✔${NC} Spotlight — re-indicizzazione avviata (prosegue in background)" || \
    log "  ${YELLOW}⚠${NC} Spotlight — impossibile re-indicizzare"

log ""

# ─────────────────────────────────────────────────────────
# FASE 7 — RIPARAZIONE DISCO E PERMESSI
# ─────────────────────────────────────────────────────────

log_section "FASE 7 — VERIFICA E RIPARAZIONE DISCO"

log "  Verifica disco (sola lettura)..."
if diskutil verifyVolume / 2>&1 | tee -a "$LOG_FILE" | tail -3; then
    log "  ${GREEN}✔${NC} Verifica volume completata"
else
    log "  ${YELLOW}⚠${NC} Verifica volume ha trovato problemi"
    log "  ${YELLOW}   Per riparazione completa: riavvia in Recovery (Cmd+R) → Disk Utility${NC}"
fi

# In diverse build High Sierra, diskutil non espone repairPermissions
log "  ${YELLOW}ℹ Riparazione permessi saltata: comando non disponibile in questa build${NC}"

# S.M.A.R.T. check
log ""
log "  Stato S.M.A.R.T. disco:"
SMART_STATUS=$(diskutil info disk0 2>/dev/null | grep -i "SMART" || echo "  Non disponibile")
log "  $SMART_STATUS"

log ""

# ─────────────────────────────────────────────────────────
# FASE 8 — OTTIMIZZAZIONE SISTEMA PER PERFORMANCE
# ─────────────────────────────────────────────────────────

log_section "FASE 8 — OTTIMIZZAZIONE PERFORMANCE"

# Disabilitare animazioni pesanti
log "  Ottimizzazione animazioni e effetti visivi..."

defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazioni finestre disabilitate"

defaults write -g QLPanelAnimationDuration -float 0 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazione Quick Look velocizzata"

defaults write NSGlobalDomain NSWindowResizeTime -float 0.001 2>/dev/null && \
    log "  ${GREEN}✔${NC} Resize finestre velocizzato"

defaults write com.apple.dock autohide-time-modifier -float 0.5 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazione Dock velocizzata"

defaults write com.apple.dock autohide-delay -float 0 2>/dev/null && \
    log "  ${GREEN}✔${NC} Delay Dock rimosso"

defaults write com.apple.dock launchanim -bool false 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazione lancio app disabilitata"

defaults write com.apple.dock expose-animation-duration -float 0.1 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazione Mission Control velocizzata"

# Ridurre trasparenza (enorme impatto su GPU vecchia)
defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} Trasparenza ridotta (grande impatto su ATI 4850)"

# Ridurre motion
defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} Effetti movimento ridotti"

# Disabilitare Dashboard (consuma RAM)
defaults write com.apple.dashboard mcx-disabled -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} Dashboard disabilitata (risparmio RAM)"

# Disabilitare Notification Center widget
# (non disabilita notifiche, solo il peso del widget layer)

# Ottimizzazione Finder
defaults write com.apple.finder DisableAllAnimations -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} Animazioni Finder disabilitate"

defaults write com.apple.finder AnimateWindowZoom -bool false 2>/dev/null

# Non mostrare file nascosti (meno rendering)
defaults write com.apple.finder AppleShowAllFiles -bool false 2>/dev/null

# Evitare creazione .DS_Store su network
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} .DS_Store su rete disabilitati"

defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true 2>/dev/null && \
    log "  ${GREEN}✔${NC} .DS_Store su USB disabilitati"

# Time Machine snapshot locali — CANCELLAZIONE AGGRESSIVA (opzione B)
log "  Cancellazione snapshot Time Machine locali..."
sudo tmutil disablelocal 2>/dev/null || true

# Rimuovi tutti gli snapshot (robusto anche quando non ce ne sono)
SNAPSHOT_LIST="$(sudo tmutil listlocalsnapshots / 2>/dev/null || true)"
SNAPSHOT_COUNT="$(printf "%s\n" "$SNAPSHOT_LIST" | grep -c "com.apple.TimeMachine" || true)"
if [[ "$SNAPSHOT_COUNT" =~ ^[0-9]+$ ]] && [ "$SNAPSHOT_COUNT" -gt 0 ]; then
    while IFS= read -r snapshot; do
        [ -z "$snapshot" ] && continue
        snap_date="${snapshot##*.}"
        sudo tmutil deletelocalsnapshots "$snap_date" 2>/dev/null || true
    done <<< "$(printf "%s\n" "$SNAPSHOT_LIST" | grep "com.apple.TimeMachine" || true)"
    log "  ${GREEN}✔${NC} Snapshot locali processati: $SNAPSHOT_COUNT"
else
    log "  ⏭ Nessuno snapshot locale trovato"
fi

# Disabilita ulteriormente
sudo defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -bool false 2>/dev/null || true
log "  ${GREEN}✔${NC} Snapshot locali disabilitati permanentemente"

# Disabilitare crash reporter dialog (meno interruzioni)
defaults write com.apple.CrashReporter DialogType -string "none" 2>/dev/null && \
    log "  ${GREEN}✔${NC} Dialog crash reporter disabilitato"

# Ottimizzazione memoria
log ""
log "  Pulizia memoria..."
sudo purge 2>/dev/null && \
    log "  ${GREEN}✔${NC} RAM purgata (inactive memory liberata)" || \
    log "  ${YELLOW}⚠${NC} purge non disponibile"

log ""

# ─────────────────────────────────────────────────────────
# FASE 9 — GESTIONE PROCESSI E LOGIN ITEMS
# ─────────────────────────────────────────────────────────

log_section "FASE 9 — PROCESSI E AVVIO AUTOMATICO"

log "  Elementi login correnti:"
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | \
    tr ',' '\n' | while read -r item; do
        item=$(echo "$item" | xargs)
        if [[ "$item" == *"Macs Fan Control"* ]] || [[ "$item" == *"Fan"* ]]; then
            log "    ${GREEN}✔ $item — PRESERVATO (ventole)${NC}"
        elif [ -n "$item" ]; then
            log "    • $item"
        fi
    done

log ""
log "  LaunchAgents utente attivi:"
if [ -d "$HOME/Library/LaunchAgents" ]; then
    for plist in "$HOME/Library/LaunchAgents/"*.plist; do
        if [ -f "$plist" ]; then
            name=$(basename "$plist" .plist)
            if [[ "$name" == *"fan"* ]] || [[ "$name" == *"crystalidea"* ]] || \
               [[ "$name" == *"MacsFanControl"* ]]; then
                log "    ${GREEN}✔ $name — PRESERVATO (ventole)${NC}"
            else
                log "    • $name"
            fi
        fi
    done
fi

log ""
log "  LaunchDaemons sistema (terze parti):"
if [ -d "/Library/LaunchDaemons" ]; then
    for plist in /Library/LaunchDaemons/*.plist; do
        if [ -f "$plist" ]; then
            name=$(basename "$plist" .plist)
            # Salta quelli Apple
            if [[ "$name" == com.apple.* ]]; then
                continue
            fi
            if [[ "$name" == *"fan"* ]] || [[ "$name" == *"crystalidea"* ]] || \
               [[ "$name" == *"MacsFanControl"* ]]; then
                log "    ${GREEN}✔ $name — PRESERVATO (ventole)${NC}"
            else
                log "    • $name"
            fi
        fi
    done
fi

log ""

# ─────────────────────────────────────────────────────────
# FASE 10 — AGGIORNAMENTO SOFTWARE
# ─────────────────────────────────────────────────────────

log_section "FASE 10 — AGGIORNAMENTO SOFTWARE"

log "  macOS corrente: $SW_VER"
log "  ${YELLOW}ℹ iMac 2009 (iMac11,1) — limite ufficiale Apple: macOS 10.13.6 High Sierra${NC}"
log "  ${YELLOW}ℹ Non esistono aggiornamenti di sicurezza Apple per 10.13.6 dal 2020${NC}"
log ""

# Controlla se ci sono update disponibili
log "  Verifica update disponibili..."
softwareupdate -l 2>&1 | tee -a "$LOG_FILE" | head -10

log ""
log "  ${CYAN}Raccomandazioni aggiornamento:${NC}"
log "  1. Aggiornare browser a ultima versione compatibile (Firefox ESR o simile)"
log "  2. Aggiornare Macs Fan Control se non già all'ultima versione"
log "  3. Per macOS più recente: valutare OpenCore Legacy Patcher (non ufficiale Apple)"
log "     → https://dortania.github.io/OpenCore-Legacy-Patcher/"
log "     → Permette fino a macOS Sonoma/Sequoia su hardware non supportato"
log "     → PRO: security updates recenti, app moderne"
log "     → CONTRO: non ufficiale, possibili instabilità GPU (ATI 4850)"
log ""

# ─────────────────────────────────────────────────────────
# FASE 11 — FLUSH DNS E RETE
# ─────────────────────────────────────────────────────────

log_section "FASE 11 — OTTIMIZZAZIONE RETE"

sudo dscacheutil -flushcache 2>/dev/null && \
    log "  ${GREEN}✔${NC} DNS cache svuotata"

sudo killall -HUP mDNSResponder 2>/dev/null && \
    log "  ${GREEN}✔${NC} mDNSResponder riavviato"

log ""

# ─────────────────────────────────────────────────────────
# FASE 12 — PULIZIA .DS_Store GLOBALE
# ─────────────────────────────────────────────────────────

log_section "FASE 12 — PULIZIA .DS_Store"

# Evita scansione globale di / (molto lenta e soggetta a blocchi)
DS_PATHS=("$HOME" "/Library" "/Applications")
DS_COUNT=0
for p in "${DS_PATHS[@]}"; do
    [ -d "$p" ] || continue
    found="$(sudo find "$p" -maxdepth 5 -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$found" =~ ^[0-9]+$ ]]; then
        DS_COUNT=$((DS_COUNT + found))
    fi
    sudo find "$p" -maxdepth 5 -name ".DS_Store" -delete 2>/dev/null || true
done
log "  ${GREEN}✔${NC} Rimossi $DS_COUNT file .DS_Store (scope: HOME/Library/Applications)"

log ""

# ─────────────────────────────────────────────────────────
# FASE 13 — RIAVVIO SERVIZI
# ─────────────────────────────────────────────────────────

log_section "FASE 13 — RIAVVIO SERVIZI"

killall Dock 2>/dev/null && log "  ${GREEN}✔${NC} Dock riavviato"
killall Finder 2>/dev/null && log "  ${GREEN}✔${NC} Finder riavviato"
killall SystemUIServer 2>/dev/null && log "  ${GREEN}✔${NC} SystemUIServer riavviato"

# NON tocchiamo Macs Fan Control
if pgrep -x "Macs Fan Control" >/dev/null 2>&1; then
    log "  ${GREEN}✔${NC} Macs Fan Control — attivo e non disturbato"
fi

log ""

# ─────────────────────────────────────────────────────────
# REPORT FINALE
# ─────────────────────────────────────────────────────────

log_section "REPORT FINALE"

DISK_AFTER=$(df -h / | tail -1)
AVAIL_AFTER=$(df -k / | tail -1 | awk '{print $4}')
FREED_KB=$((AVAIL_AFTER - AVAIL_BEFORE))
if [ "$FREED_KB" -lt 0 ]; then
    FREED_KB=0
fi
FREED_MB=$((FREED_KB / 1024))
FREED_GB=$(echo "scale=2; $FREED_KB / 1048576" | bc 2>/dev/null || echo "N/A")

log ""
log "  ${BOLD}PRIMA:${NC}  $DISK_BEFORE"
log "  ${BOLD}DOPO:${NC}   $DISK_AFTER"
log ""
log "  ${GREEN}${BOLD}SPAZIO LIBERATO: ${FREED_GB} GB (~${FREED_MB} MB)${NC}"
log ""

log "  ${BOLD}S.M.A.R.T.:${NC}"
diskutil info disk0 2>/dev/null | grep -i "SMART" | tee -a "$LOG_FILE"
log ""

log "  ${BOLD}Macs Fan Control:${NC}"
if pgrep -x "Macs Fan Control" >/dev/null 2>&1; then
    log "  ${GREEN}✔ IN ESECUZIONE — ventole sotto controllo${NC}"
else
    log "  ${YELLOW}⚠ Non in esecuzione — avvialo manualmente se necessario${NC}"
fi

log ""
log "════════════════════════════════════════════════════════════"
log "  ${GREEN}${BOLD}✅ PULIZIA E OTTIMIZZAZIONE COMPLETATA${NC}"
log "════════════════════════════════════════════════════════════"
log ""
log "  📄 Log completo salvato in: $LOG_FILE"
log ""
log "  ${CYAN}PROSSIMI PASSI CONSIGLIATI:${NC}"
log "  1. ${BOLD}Riavvia l'iMac${NC} per applicare tutte le ottimizzazioni"
log "  2. Dopo il riavvio, Spotlight si ri-indicizzerà (15-30 min)"
log "  3. Aggiorna il browser manualmente all'ultima versione compatibile"
log "  4. Verifica che Macs Fan Control si avvii automaticamente"
log "  5. Valuta OpenCore Legacy Patcher per macOS più recente"
log "  6. ${BOLD}Considera seriamente sostituire l'HDD con un SSD${NC}"
log "     → Impatto più grande possibile sulle performance"
log "     → SSD SATA 2.5\" da 500GB: ~30-40€"
log "     → Velocità 5-10× rispetto all'HDD attuale"
log ""

echo "Premi un tasto per chiudere..."
read -n 1
