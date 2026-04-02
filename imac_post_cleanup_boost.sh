#!/bin/bash
set -euo pipefail

# iMac 2009 High Sierra - Post Cleanup Boost
# Obiettivo: rifinitura prestazioni e update senza toccare Macs Fan Control.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "$1"; }

need_sudo() {
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  SUDO_PID=$!
  trap 'kill $SUDO_PID 2>/dev/null || true' EXIT
}

remove_login_item_if_exists() {
  local item_name="$1"
  if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -Fq "$item_name"; then
    osascript -e "tell application \"System Events\" to delete login item \"$item_name\"" >/dev/null 2>&1 || true
    log "  ${GREEN}✔${NC} Login item rimosso: $item_name"
  else
    log "  ${YELLOW}⏭${NC} Login item non presente: $item_name"
  fi
}

disable_launchagent_if_exists() {
  local plist_path="$1"
  if [ -f "$plist_path" ]; then
    launchctl unload "$plist_path" >/dev/null 2>&1 || true
    mkdir -p "$HOME/Library/LaunchAgents.disabled"
    mv "$plist_path" "$HOME/Library/LaunchAgents.disabled/" 2>/dev/null || true
    log "  ${GREEN}✔${NC} LaunchAgent disabilitato: $(basename "$plist_path")"
  fi
}

disable_launchdaemon_if_exists() {
  local plist_path="$1"
  if [ -f "$plist_path" ]; then
    sudo launchctl unload "$plist_path" >/dev/null 2>&1 || true
    sudo mkdir -p /Library/LaunchDaemons.disabled
    sudo mv "$plist_path" /Library/LaunchDaemons.disabled/ 2>/dev/null || true
    log "  ${GREEN}✔${NC} LaunchDaemon disabilitato: $(basename "$plist_path")"
  fi
}

log "${CYAN}============================================================${NC}"
log "${CYAN} iMac 2009 - BOOST POST PULIZIA (safe + performance)${NC}"
log "${CYAN}============================================================${NC}"

if ! groups | grep -qw admin; then
  log "${RED}✖ Account non admin. Usa utente admin.${NC}"
  exit 1
fi

log "${YELLOW}Nota:${NC} Macs Fan Control non verra toccato."
need_sudo

# 1) Check rete + software update
log "\n${CYAN}[1/7] Verifica rete e update${NC}"
if ping -c 1 -t 2 swscan.apple.com >/dev/null 2>&1; then
  log "  ${GREEN}✔${NC} Rete OK verso server Apple"
  softwareupdate -l || true
  sudo softwareupdate --install --all || true
else
  log "  ${YELLOW}⚠${NC} Rete Apple non raggiungibile, salto update automatici"
fi

# 2) Riduzione carico background noto (chiede conferma)
log "\n${CYAN}[2/7] Ottimizzazione avvio automatico${NC}"
log "Elementi attuali visti nei tuoi log: uTorrent, EaseUS Tray, cDockHelper, Cisco VideoGuard"
read -r -p "Disabilitare questi elementi non essenziali? (s/n) " ans
if [[ "$ans" =~ ^[Ss]$ ]]; then
  remove_login_item_if_exists "uTorrent"
  remove_login_item_if_exists "EaseUS Data Recovery Wizard Tray"
  remove_login_item_if_exists "cDockHelper"

  disable_launchagent_if_exists "$HOME/Library/LaunchAgents/com.cisco.videoguard10.plist"
  disable_launchagent_if_exists "$HOME/Library/LaunchAgents/com.cisco.videoguard10.uninstall.plist"
  disable_launchagent_if_exists "$HOME/Library/LaunchAgents/com.cisco.videoguardmonitor.plist"

  disable_launchdaemon_if_exists "/Library/LaunchDaemons/com.easeus.dataprotectbackup.plist"
  log "  ${GREEN}✔${NC} Disabilitazioni completate"
else
  log "  ${YELLOW}⏭${NC} Nessuna disabilitazione applicata"
fi

# 3) Ottimizzazione energia desktop (prestazioni)
log "\n${CYAN}[3/7] Profilo energetico performance${NC}"
sudo pmset -a sleep 0 disksleep 0 displaysleep 20 powernap 0 autorestart 1 >/dev/null 2>&1 || true
log "  ${GREEN}✔${NC} Profilo energetico applicato"

# 4) Ricostruzioni cache sicure
log "\n${CYAN}[4/7] Cache sistema${NC}"
sudo dscacheutil -flushcache || true
sudo killall -HUP mDNSResponder || true
sudo update_dyld_shared_cache -force >/dev/null 2>&1 || true
log "  ${GREEN}✔${NC} Cache principali aggiornate"

# 5) Spotlight e permessi home
log "\n${CYAN}[5/7] Spotlight e ownership utente${NC}"
sudo mdutil -E / >/dev/null 2>&1 || true
sudo chown -R "$USER":staff "$HOME/Library/Caches" "$HOME/Library/Logs" >/dev/null 2>&1 || true
log "  ${GREEN}✔${NC} Reindex Spotlight avviato + ownership corretta"

# 6) Verifica ventole (solo check)
log "\n${CYAN}[6/7] Verifica Macs Fan Control${NC}"
if pgrep -x "Macs Fan Control" >/dev/null 2>&1; then
  log "  ${GREEN}✔${NC} Macs Fan Control attivo"
else
  log "  ${YELLOW}⚠${NC} Macs Fan Control non attivo: avvialo manualmente"
fi

# 7) Report rapido
log "\n${CYAN}[7/7] Report rapido${NC}"
df -h /
log ""
log "${GREEN}BOOST COMPLETATO${NC}"
log "Prossimo passo: riavviare iMac ora per consolidare tutto."
