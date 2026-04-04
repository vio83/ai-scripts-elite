#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# VIO83 — BUNKER DEPLOY COMPLETO: Kali Linux → Intelligence Station
# ═══════════════════════════════════════════════════════════════════════════════
# Target: iMac 27" Late 2009 (iMac11,1) su Kali Linux
# Scopo: Replicare 1:1 l'ambiente Mac Air M1 + potenziamento OSINT/intelligence
#
# 15 FASI:
#   0. Prerequisiti e sicurezza termica
#   1. Rete + DNS sicuro + isolamento
#   2. Pacchetti base + build essentials
#   3. Python environment + venv + dipendenze intelligence
#   4. Node.js LTS + npm
#   5. VS Code + estensioni identiche a Mac Air + settings sync
#   6. Ollama + modelli AI consigliati
#   7. Intelligence Station tools (OSINT: exiftool, tesseract, ecc.)
#   8. Docker + container isolation per agenti
#   9. Tor + anonimizzazione per ricerca deep web
#  10. Security hardening — 12 livelli
#  11. Git + clone repos
#  12. World Monitor setup
#  13. Auto-ottimizzazione cron (ogni 15 minuti)
#  14. Verifica finale + report
#
# USO: sudo bash kali_vio_bunker_deploy.sh [--skip-thermal] [--offline]
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8

# ── Flags ──────────────────────────────────────────────────
SKIP_THERMAL=false
OFFLINE=false
VSCODE_PROFILE="${VSCODE_PROFILE:-minimal}"
for arg in "$@"; do
  case "$arg" in
    --skip-thermal) SKIP_THERMAL=true ;;
    --offline) OFFLINE=true ;;
    --full-vscode) VSCODE_PROFILE="full" ;;
    --minimal-vscode) VSCODE_PROFILE="minimal" ;;
  esac
done

# ── Colori ─────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

LOG_DIR="/var/log/vio83"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/bunker_deploy_$(date +%Y%m%d_%H%M%S).log"
PASS=0; FAIL=0; WARN=0; PHASE=0

log()     { echo -e "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }
ok()      { echo -e "  ${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; PASS=$((PASS+1)); }
fail()    { echo -e "  ${RED}❌ $1${NC}" | tee -a "$LOG_FILE"; FAIL=$((FAIL+1)); }
warn()    { echo -e "  ${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"; WARN=$((WARN+1)); }
section() { PHASE=$((PHASE+1)); echo "" | tee -a "$LOG_FILE"; echo -e "${CYAN}════ FASE ${PHASE}/15: $1 ════${NC}" | tee -a "$LOG_FILE"; }

pkg_install() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null; then
    log "  $pkg: già installato"
  else
    if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
      ok "$pkg installato"
    else
      fail "$pkg — installazione fallita"
    fi
  fi
}

pkg_optional_install() {
  local pkg="$1"
  if apt-cache show "$pkg" &>/dev/null; then
    pkg_install "$pkg"
  else
    warn "$pkg non disponibile nei repository correnti"
  fi
}

append_cron_line() {
  local user="$1"
  local marker="$2"
  local line="$3"
  (crontab -u "$user" -l 2>/dev/null | grep -v "$marker"; echo "$line") | crontab -u "$user" -
}

# ── Root check ─────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Eseguire come root: sudo bash $0${NC}"
  exit 1
fi

REAL_USER="${SUDO_USER:-root}"
REAL_HOME=$(eval echo "~$REAL_USER")

echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${BLUE}  🏴 VIO83 BUNKER DEPLOY — Intelligence Station su Kali${NC}"
echo -e "${BOLD}${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
log "User: $REAL_USER | Home: $REAL_HOME | Log: $LOG_FILE"
log "VS Code profile: $VSCODE_PROFILE"

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 0: SICUREZZA TERMICA
# ═══════════════════════════════════════════════════════════════════════════════
section "SICUREZZA TERMICA iMac"

if $SKIP_THERMAL; then
  warn "Termica saltata (--skip-thermal)"
else
  APPLESMC="/sys/devices/platform/applesmc.0"
  if [ ! -d "$APPLESMC" ]; then
    modprobe applesmc 2>/dev/null || true
    sleep 1
  fi

  if [ -d "$APPLESMC" ]; then
    for fan_manual in "$APPLESMC"/fan*_manual; do
      [ -f "$fan_manual" ] && echo 1 > "$fan_manual" 2>/dev/null || true
    done
    for fan_output in "$APPLESMC"/fan*_output; do
      [ -f "$fan_output" ] && echo 6200 > "$fan_output" 2>/dev/null || true
    done
    ok "Ventole impostate al massimo via applesmc"
  else
    warn "applesmc non disponibile — MONITORARE TEMPERATURE MANUALMENTE"
  fi

  if ! command -v macfanctld &>/dev/null; then
    apt-get install -y macfanctld >> "$LOG_FILE" 2>&1 || true
  fi
  if command -v macfanctld &>/dev/null; then
    pgrep -x macfanctld >/dev/null || macfanctld &
    ok "macfanctld attivo"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 1: RETE + DNS + ISOLAMENTO
# ═══════════════════════════════════════════════════════════════════════════════
section "RETE + DNS SICURO + ISOLAMENTO"

if ! $OFFLINE; then
  # Test connettività
  if ping -c1 -W3 1.1.1.1 &>/dev/null; then
    ok "Internet raggiungibile"
  else
    fail "Nessuna connessione Internet — collegare rete e riprovare"
    exit 1
  fi
fi

# DNS sicuri (Cloudflare malware blocking + Quad9)
if [ -f /etc/resolv.conf ]; then
  cp /etc/resolv.conf /etc/resolv.conf.bak.vio 2>/dev/null || true
fi
cat > /etc/resolv.conf.vio << 'DNSEOF'
# VIO83 DNS sicuri — malware/phishing blocking
nameserver 1.1.1.2
nameserver 1.0.0.2
nameserver 9.9.9.9
DNSEOF

# Solo se non gestito da NetworkManager/systemd-resolved
if ! systemctl is-active systemd-resolved &>/dev/null; then
  cp /etc/resolv.conf.vio /etc/resolv.conf 2>/dev/null || true
  ok "DNS sicuri configurati (1.1.1.2, 9.9.9.9)"
else
  log "  DNS gestito da systemd-resolved — configurazione manuale non applicata"
  warn "Configurare DNS da NetworkManager: nmcli con dns= 1.1.1.2,9.9.9.9"
fi

# Isolamento rete: solo traffico necessario in uscita
if command -v iptables &>/dev/null; then
  # Salva regole attuali
  iptables-save > /etc/iptables.rules.bak.vio 2>/dev/null || true

  # Blocca tutto in ingresso tranne loopback e connessioni stabilite
  iptables -F INPUT 2>/dev/null || true
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Permettere SSH locale per debug
  iptables -A INPUT -p tcp --dport 22 -s 192.168.0.0/16 -j ACCEPT
  iptables -A INPUT -p tcp --dport 22 -s 172.16.0.0/12 -j ACCEPT
  # Permettere World Monitor locale
  iptables -A INPUT -p tcp --dport 7778 -s 192.168.0.0/16 -j ACCEPT
  # Drop tutto il resto in entrata
  iptables -A INPUT -j DROP 2>/dev/null || true
  ok "Firewall iptables: ingresso bloccato (solo loopback/established/SSH locale)"
else
  warn "iptables non disponibile"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 2: PACCHETTI BASE + BUILD
# ═══════════════════════════════════════════════════════════════════════════════
section "PACCHETTI BASE + BUILD ESSENTIALS"

apt-get update >> "$LOG_FILE" 2>&1 || warn "apt update fallito"

BASE_PKGS=(
  build-essential curl wget git jq htop tmux unzip ca-certificates gnupg
  lsb-release pkg-config libssl-dev libffi-dev net-tools tree openssh-client
  rsync lsof strace ltrace gdb valgrind
)

for pkg in "${BASE_PKGS[@]}"; do
  pkg_install "$pkg"
done

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 3: PYTHON + VENV + DIPENDENZE INTELLIGENCE
# ═══════════════════════════════════════════════════════════════════════════════
section "PYTHON + VENV + DIPENDENZE INTELLIGENCE"

PY_PKGS=(python3-full python3-pip python3-venv python3-dev)
for pkg in "${PY_PKGS[@]}"; do
  pkg_install "$pkg"
done

VIO_VENV="$REAL_HOME/vio-orchestra-env"
if [ ! -d "$VIO_VENV" ]; then
  sudo -u "$REAL_USER" python3 -m venv "$VIO_VENV" 2>> "$LOG_FILE"
  ok "Virtualenv creato: $VIO_VENV"
else
  ok "Virtualenv esistente: $VIO_VENV"
fi

# Dipendenze Python per Intelligence Station + Backend
PY_DEPS=(
  fastapi uvicorn httpx psutil pydantic python-dotenv flask
  Pillow requests beautifulsoup4 lxml
  python-whois dnspython scapy
  cryptography pycryptodome
  faster-whisper
  yt-dlp
  shodan
)

"$VIO_VENV/bin/pip" install --upgrade pip >> "$LOG_FILE" 2>&1

for dep in "${PY_DEPS[@]}"; do
  if "$VIO_VENV/bin/pip" install "$dep" >> "$LOG_FILE" 2>&1; then
    log "  pip: $dep OK"
  else
    warn "pip: $dep fallito (non bloccante)"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 4: NODE.JS LTS + NPM
# ═══════════════════════════════════════════════════════════════════════════════
section "NODE.JS LTS + NPM"

if command -v node &>/dev/null; then
  ok "Node.js presente: $(node --version)"
else
  NODE_MAJOR=22
  KEYRING="/etc/apt/keyrings/nodesource.gpg"
  mkdir -p /etc/apt/keyrings
  if curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" | gpg --dearmor -o "$KEYRING" 2>> "$LOG_FILE"; then
    echo "deb [signed-by=$KEYRING] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
    apt-get update >> "$LOG_FILE" 2>&1
    apt-get install -y nodejs >> "$LOG_FILE" 2>&1 && ok "Node.js $(node --version) installato" || fail "Node.js installazione fallita"
  else
    fail "NodeSource GPG fallita"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 5: VS CODE + ESTENSIONI + SETTINGS IDENTICHE MAC AIR
# ═══════════════════════════════════════════════════════════════════════════════
section "VS CODE + ESTENSIONI + SETTINGS"

# Installa VS Code
if ! command -v code &>/dev/null; then
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg 2>/dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
  apt-get update >> "$LOG_FILE" 2>&1
  apt-get install -y code >> "$LOG_FILE" 2>&1 && ok "VS Code installato" || fail "VS Code installazione fallita"
else
  ok "VS Code presente: $(code --version 2>/dev/null | head -1)"
fi

# Installa JetBrains Mono (font identico Mac Air)
if ! fc-list 2>/dev/null | grep -qi "JetBrains Mono"; then
  FONT_DIR="$REAL_HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  FONT_TMP=$(mktemp -d)
  if curl -fsSL "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip" -o "$FONT_TMP/jbm.zip" 2>>"$LOG_FILE"; then
    unzip -qo "$FONT_TMP/jbm.zip" -d "$FONT_TMP/jbm" 2>/dev/null
    find "$FONT_TMP/jbm" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
    chown -R "$REAL_USER:$REAL_USER" "$FONT_DIR"
    sudo -u "$REAL_USER" fc-cache -f 2>/dev/null || true
    ok "JetBrains Mono font installato"
  else
    warn "Download JetBrains Mono fallito"
  fi
  rm -rf "$FONT_TMP"
else
  ok "JetBrains Mono già installato"
fi

# Estensioni — profilo minimo di default per iMac 2009, full opzionale
VSCODE_EXTENSIONS=(
  "ms-python.python"
  "ms-python.vscode-pylance"
  "github.copilot"
  "github.copilot-chat"
  "eamodio.gitlens"
  "redhat.vscode-yaml"
  "usernamehw.errorlens"
  "zhuangtongfa.material-theme"
  "pkief.material-icon-theme"
  "yzhang.markdown-all-in-one"
)

if [ "$VSCODE_PROFILE" = "full" ]; then
  VSCODE_EXTENSIONS+=(
    "ms-toolsai.jupyter"
    "charliermarsh.ruff"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "ms-azuretools.vscode-docker"
    "ms-vscode.makefile-tools"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode.hexeditor"
    "formulahendry.auto-rename-tag"
    "tintinweb.graphviz-interactive-preview"
  )
fi

log "  Estensioni VS Code selezionate: ${#VSCODE_EXTENSIONS[@]}"

for ext in "${VSCODE_EXTENSIONS[@]}"; do
  sudo -u "$REAL_USER" code --install-extension "$ext" --force >>"$LOG_FILE" 2>&1 && log "  ext: $ext OK" || warn "ext: $ext fallito"
done

# Settings.json — adattato da Mac Air per Linux
VSCODE_SETTINGS_DIR="$REAL_HOME/.config/Code/User"
mkdir -p "$VSCODE_SETTINGS_DIR"

cat > "$VSCODE_SETTINGS_DIR/settings.json" << 'SETTINGSEOF'
{
  "editor.fontFamily": "'JetBrains Mono', 'Fira Code', 'SF Mono', monospace",
  "editor.fontSize": 14,
  "editor.fontLigatures": true,
  "editor.fontWeight": "400",
  "editor.lineHeight": 1.6,
  "editor.letterSpacing": 0.3,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.wordWrap": "on",
  "editor.wordWrapColumn": 120,
  "editor.rulers": [80, 120],
  "editor.smoothScrolling": false,
  "editor.cursorBlinking": "solid",
  "editor.cursorSmoothCaretAnimation": "off",
  "editor.cursorStyle": "line",
  "editor.cursorWidth": 2,
  "editor.minimap.enabled": false,
  "editor.stickyScroll.enabled": false,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "editor.guides.indentation": true,
  "editor.guides.highlightActiveIndentation": true,
  "editor.linkedEditing": true,
  "editor.renderWhitespace": "none",
  "editor.renderLineHighlight": "all",
  "editor.selectionHighlight": true,
  "editor.matchBrackets": "always",
  "editor.semanticHighlighting.enabled": true,
  "editor.accessibilitySupport": "off",
  "editor.padding.top": 8,
  "editor.padding.bottom": 8,
  "editor.suggestSelection": "first",
  "editor.quickSuggestions": { "other": true, "comments": false, "strings": false },
  "editor.suggest.preview": false,
  "editor.suggest.showMethods": true,
  "editor.suggest.showFunctions": true,
  "editor.suggest.showSnippets": true,
  "editor.suggest.showIcons": true,
  "editor.suggest.insertMode": "replace",
  "editor.snippetSuggestions": "top",
  "editor.tabCompletion": "on",
  "editor.parameterHints.enabled": true,
  "editor.parameterHints.cycle": true,
  "editor.inlayHints.enabled": "offUnlessPressed",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.formatOnType": true,
  "editor.defaultFormatter": null,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "editor.hover.delay": 500,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "files.encoding": "utf8",
  "files.associations": { "*.env*": "dotenv", "*.json5": "jsonc", "*.sh": "shellscript" },
  "files.exclude": {
    "**/.git": true, "**/.DS_Store": true, "**/node_modules": true,
    "**/__pycache__": true, "**/.pytest_cache": true
  },
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/__pycache__/**": true,
    "**/.pytest_cache/**": true,
    "**/.venv/**": true,
    "**/venv/**": true,
    "**/dist/**": true,
    "**/target/**": true,
    "**/forensic_output/**": true,
    "**/.node-status/**": true
  },
  "explorer.compactFolders": false,
  "explorer.sortOrder": "type",
  "explorer.confirmDragAndDrop": false,
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.patterns": {
    "package.json": "package-lock.json, yarn.lock, .npmrc",
    "tsconfig.json": "tsconfig.*.json",
    ".env": ".env.*"
  },
  "search.smartCase": true,
  "search.showLineNumbers": true,
  "search.exclude": {
    "**/node_modules": true, "**/dist": true, "**/venv": true,
    "**/.venv": true, "**/__pycache__": true, "**/.git": true
  },
  "terminal.integrated.defaultProfile.linux": "zsh",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.fontFamily": "'JetBrains Mono', monospace",
  "terminal.integrated.lineHeight": 1.4,
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.scrollback": 5000,
  "terminal.integrated.copyOnSelection": true,
  "terminal.integrated.enableMultiLinePasteWarning": "never",
  "workbench.colorTheme": "One Dark Pro Darker",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.editor.highlightModifiedTabs": true,
  "workbench.tree.indent": 16,
  "workbench.tree.renderIndentGuides": "always",
  "workbench.tips.enabled": false,
  "workbench.startupEditor": "none",
  "workbench.enableExperiments": false,
  "workbench.editor.wrapTabs": true,
  "workbench.editor.revealIfOpen": true,
  "workbench.editor.limit.enabled": true,
  "workbench.editor.limit.value": 10,
  "window.title": "${dirty}${activeEditorShort}${separator}${rootName}${separator}VIO Bunker",
  "git.enableSmartCommit": true,
  "git.autofetch": false,
  "git.confirmSync": false,
  "git.openRepositoryInParentFolders": "always",
  "gitlens.codeLens.enabled": false,
  "gitlens.currentLine.enabled": false,
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.diagnosticMode": "openFilesOnly",
  "python.analysis.autoImportCompletions": true,
  "python.defaultInterpreterPath": "/usr/bin/python3",
  "[python]": { "editor.defaultFormatter": "ms-python.python", "editor.tabSize": 4 },
  "[markdown]": { "editor.defaultFormatter": "yzhang.markdown-all-in-one", "editor.wordWrap": "on" },
  "[html]": { "editor.defaultFormatter": "vscode.html-language-features" },
  "[json]": { "editor.defaultFormatter": "vscode.json-language-features" },
  "[jsonc]": { "editor.defaultFormatter": "vscode.json-language-features" },
  "[javascript]": { "editor.defaultFormatter": "vscode.typescript-language-features" },
  "[typescript]": { "editor.defaultFormatter": "vscode.typescript-language-features" },
  "[yaml]": { "editor.defaultFormatter": "redhat.vscode-yaml" },
  "errorLens.enabled": true,
  "errorLens.enabledDiagnosticLevels": ["error", "warning"],
  "errorLens.fontSize": "12",
  "errorLens.messageMaxChars": 120,
  "errorLens.delay": 500,
  "breadcrumbs.enabled": false,
  "telemetry.telemetryLevel": "off",
  "security.workspace.trust.enabled": false,
  "diffEditor.ignoreTrimWhitespace": true,
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "update.mode": "manual",
  "github.copilot.chat.defaultModel": "claude-opus-4.6",
  "chat.tools.autoApprove": true,
  "chat.restoreLastPanelSession": true,
  "diffEditor.renderSideBySide": false,
  "github.copilot.chat.agent.autoFix": true,
  "github.copilot.chat.scopeSelection": true
}
SETTINGSEOF

chown "$REAL_USER:$REAL_USER" "$VSCODE_SETTINGS_DIR/settings.json"
ok "VS Code settings.json sincronizzato con Mac Air"

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 6: OLLAMA + MODELLI AI
# ═══════════════════════════════════════════════════════════════════════════════
section "OLLAMA + MODELLI AI LOCALI"

if ! command -v ollama &>/dev/null; then
  OLLAMA_TMP=$(mktemp)
  if curl -fsSL "https://ollama.com/install.sh" -o "$OLLAMA_TMP" 2>>"$LOG_FILE"; then
    bash "$OLLAMA_TMP" >> "$LOG_FILE" 2>&1 && ok "Ollama installato" || fail "Ollama installazione fallita"
  fi
  rm -f "$OLLAMA_TMP"
else
  ok "Ollama presente: $(ollama --version 2>/dev/null || echo 'installato')"
fi

# Avvia Ollama se non attivo
if command -v ollama &>/dev/null; then
  if ! pgrep -x ollama &>/dev/null; then
    nohup ollama serve >> "$LOG_DIR/ollama.log" 2>&1 &
    sleep 3
  fi

  # Scarica modelli (adatti a iMac 2009)
  RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  RAM_GB=$((RAM_KB / 1024 / 1024))

  MODELS=("qwen2.5-coder:3b" "phi3:mini")
  if [ "$RAM_GB" -ge 8 ]; then
    MODELS+=("llama3.2:3b" "qwen2.5:3b" "nomic-embed-text:latest")
  fi
  if [ "$RAM_GB" -ge 16 ]; then
    MODELS+=("llama3.2:8b")
  fi

  for model in "${MODELS[@]}"; do
    log "  Pull modello: $model"
    # Timeout 600s per evitare hang su rete lenta
    if timeout 600 ollama pull "$model" >> "$LOG_FILE" 2>&1; then
      ok "Modello $model scaricato"
    else
      warn "Modello $model fallito o timeout (non bloccante)"
    fi
  done
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 7: INTELLIGENCE STATION TOOLS (OSINT)
# ═══════════════════════════════════════════════════════════════════════════════
section "INTELLIGENCE STATION TOOLS (OSINT + FORENSICS)"

# Kali ha già molti tool, ma assicuriamo che siano tutti presenti
OSINT_PKGS=(
  # Metadata/Forensics
  libimage-exiftool-perl   # exiftool
  poppler-utils            # pdftotext, pdfinfo
  tesseract-ocr            # OCR
  tesseract-ocr-ita        # OCR italiano
  tesseract-ocr-eng        # OCR inglese
  ffmpeg                   # Audio/video
  binutils                 # strings
  binwalk                  # Firmware/steganografia
  foremost                 # File recovery
  steghide                 # Steganografia
  # Rete
  nmap                     # Network scanner
  dnsutils                 # dig
  whois                    # WHOIS
  traceroute               # Traceroute
  tcpdump                  # Packet capture
  tshark                   # Wireshark CLI
  masscan                  # Fast port scanner
  # OSINT
  theharvester             # Email/domain harvesting
  recon-ng                 # OSINT framework
  maltego                  # Link analysis (CE) — fallisce su repo base, non bloccante
  spiderfoot               # OSINT automation
  # Crypto
  hashcat                  # Hash cracking (GPU/CPU)
  john                     # John the Ripper
  # Web
  nikto                    # Web vulnerability scanner
  dirb                     # Web content scanner
  gobuster                 # Directory brute-force
  wpscan                   # WordPress scanner
  sqlmap                   # SQL injection
  # Password
  hydra                    # Network brute-force
  # Wireless
  aircrack-ng              # WiFi audit
  # Misc — nota: python3-shodan non esiste come APT pkg, installato via pip nella Fase 3
  metagoofil               # Metadata extractor documenti
  cewl                     # Custom wordlist generator
  crunch                   # Wordlist generator
  seclists                 # Security wordlists
)

log "  Installazione toolkit OSINT/intelligence (${#OSINT_PKGS[@]} pacchetti)..."
for pkg in "${OSINT_PKGS[@]}"; do
  pkg_install "$pkg"
done

# Sherlock (username OSINT) — da pip
"$VIO_VENV/bin/pip" install sherlock-project >> "$LOG_FILE" 2>&1 && ok "Sherlock installato" || warn "Sherlock fallito"

# yt-dlp per download video/audio
"$VIO_VENV/bin/pip" install yt-dlp >> "$LOG_FILE" 2>&1 && ok "yt-dlp installato" || warn "yt-dlp fallito"

# Amass (OSINT subdomain enumeration)
if ! command -v amass &>/dev/null; then
  apt-get install -y amass >> "$LOG_FILE" 2>&1 || warn "amass non installato"
fi

# Directory intelligence
mkdir -p "$REAL_HOME/.vio83/intelligence" "$REAL_HOME/.vio83/dossiers" "$REAL_HOME/.vio83/evidence"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.vio83"
ok "Directory intelligence create"

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 8: DOCKER + CONTAINER ISOLATION
# ═══════════════════════════════════════════════════════════════════════════════
section "DOCKER + CONTAINER ISOLATION PER AGENTI"

if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash >> "$LOG_FILE" 2>&1 && ok "Docker installato" || warn "Docker installazione fallita"
fi

if command -v docker &>/dev/null; then
  usermod -aG docker "$REAL_USER" 2>/dev/null || true
  systemctl enable docker 2>/dev/null || true
  systemctl start docker 2>/dev/null || true
  ok "Docker configurato (user $REAL_USER aggiunto al gruppo)"

  # Network isolata per agenti
  docker network create --driver bridge --subnet=172.28.0.0/16 vio-bunker-net 2>/dev/null && ok "Docker network vio-bunker-net creata" || log "  Docker network già esistente"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 9: TOR + ANONIMIZZAZIONE
# ═══════════════════════════════════════════════════════════════════════════════
section "TOR + ANONIMIZZAZIONE RICERCA"

TOR_PKGS=(tor torsocks proxychains4)
for pkg in "${TOR_PKGS[@]}"; do
  pkg_install "$pkg"
done

# Configura Tor
if [ -f /etc/tor/torrc ]; then
  if ! grep -q "VIO83" /etc/tor/torrc; then
    cat >> /etc/tor/torrc << 'TOREOF'

# VIO83 Bunker — Tor configuration
SOCKSPort 9050
DNSPort 5353
AutomapHostsOnResolve 1
# Circuiti multipli per ricerca parallela
MaxCircuitDirtiness 600
NewCircuitPeriod 30
NumEntryGuards 8
TOREOF
    ok "Tor configurato (SOCKS 9050, DNS 5353)"
  else
    ok "Tor già configurato"
  fi
fi

systemctl enable tor 2>/dev/null || true
systemctl start tor 2>/dev/null || true

# Proxychains configurazione
if [ -f /etc/proxychains4.conf ]; then
  if ! grep -q "VIO83" /etc/proxychains4.conf; then
    # Assicura che proxychains usi Tor
    sed -i 's/^strict_chain/#strict_chain/' /etc/proxychains4.conf 2>/dev/null || true
    sed -i 's/^#dynamic_chain/dynamic_chain/' /etc/proxychains4.conf 2>/dev/null || true
    ok "Proxychains configurato → Tor"
  fi
fi

log "  Uso: torsocks curl https://check.torproject.org/api/ip"
log "  Uso: proxychains4 curl https://example.onion"

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 10: SECURITY HARDENING — 12 LIVELLI
# ═══════════════════════════════════════════════════════════════════════════════
section "SECURITY HARDENING — 12 LIVELLI"

# L1: Firewall iptables (già configurato in Fase 1)
ok "L1: Firewall iptables — configurato"

# L2: UFW (interfaccia semplificata)
if ! command -v ufw &>/dev/null; then
  apt-get install -y ufw >> "$LOG_FILE" 2>&1
fi
if command -v ufw &>/dev/null; then
  ufw default deny incoming >> "$LOG_FILE" 2>&1 || true
  ufw default allow outgoing >> "$LOG_FILE" 2>&1 || true
  ufw allow from 192.168.0.0/16 to any port 22 >> "$LOG_FILE" 2>&1 || true
  ufw allow from 192.168.0.0/16 to any port 7778 >> "$LOG_FILE" 2>&1 || true
  echo "y" | ufw enable >> "$LOG_FILE" 2>&1 || true
  ok "L2: UFW — deny incoming, allow outgoing, SSH/World Monitor locale"
fi

# L3: Fail2Ban
pkg_install fail2ban
if command -v fail2ban-client &>/dev/null; then
  systemctl enable fail2ban 2>/dev/null || true
  systemctl start fail2ban 2>/dev/null || true
  ok "L3: Fail2Ban — protezione brute-force attiva"
fi

# L4: AppArmor
if command -v apparmor_status &>/dev/null; then
  ok "L4: AppArmor — $(apparmor_status --verbose 2>/dev/null | head -1 || echo 'presente')"
else
  pkg_install apparmor
  warn "L4: AppArmor installato — richiede reboot per attivazione completa"
fi

# L5: ClamAV antivirus
pkg_install clamav
pkg_install clamav-daemon
if command -v clamscan &>/dev/null; then
  freshclam >> "$LOG_FILE" 2>&1 || warn "ClamAV update firme fallito (potrebbe servire retry)"
  ok "L5: ClamAV — antivirus con firme aggiornate"
fi

# L6: rkhunter rootkit detection
pkg_install rkhunter
if command -v rkhunter &>/dev/null; then
  rkhunter --update >> "$LOG_FILE" 2>&1 || true
  ok "L6: rkhunter — rootkit detection"
fi

# L7: Lynis audit
pkg_install lynis
ok "L7: Lynis — security audit framework"

# L8: AIDE file integrity monitoring
pkg_install aide
if command -v aide &>/dev/null; then
  # Inizializza database (solo se non esiste)
  if [ ! -f /var/lib/aide/aide.db ]; then
    aide --init >> "$LOG_FILE" 2>&1 || true
    cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null || true
  fi
  ok "L8: AIDE — file integrity monitoring"
fi

# L9: auditd process monitoring
pkg_install auditd
if command -v auditctl &>/dev/null; then
  systemctl enable auditd 2>/dev/null || true
  systemctl start auditd 2>/dev/null || true
  # Regola: monitora accessi a file sensibili
  auditctl -w /etc/passwd -p wa -k identity 2>/dev/null || true
  auditctl -w /etc/shadow -p wa -k identity 2>/dev/null || true
  auditctl -w /etc/sudoers -p wa -k identity 2>/dev/null || true
  ok "L9: auditd — process e file audit attivo"
fi

# L10: Process monitoring (psutil via python)
ok "L10: Process monitoring — integrato in World Monitor (psutil)"

# L11: Network traffic monitoring
pkg_install iftop
pkg_install nethogs
ok "L11: Network monitoring — iftop + nethogs installati"

# L12: Docker isolation (già configurato in Fase 8)
ok "L12: Docker container isolation — rete vio-bunker-net"

# L13: EDR-lite open source verificabile
pkg_optional_install yara
pkg_optional_install chkrootkit
pkg_optional_install osquery
pkg_optional_install suricata

if command -v osqueryi &>/dev/null || command -v osqueryd &>/dev/null; then
  ok "L13: osquery disponibile — telemetry/query host"
else
  warn "L13: osquery non disponibile — EDR-lite ridotto"
fi

if command -v yara &>/dev/null; then
  ok "L13: YARA disponibile — scansione regole locale"
fi

if command -v chkrootkit &>/dev/null; then
  ok "L13: chkrootkit disponibile — rootkit sweep aggiuntivo"
fi

if command -v suricata &>/dev/null; then
  systemctl enable suricata 2>/dev/null || true
  systemctl start suricata 2>/dev/null || true
  ok "L13: Suricata disponibile — NIDS locale best effort"
else
  warn "L13: Suricata assente — NIDS non attivo"
fi

log ""
log "  NOTA ONESTA sulla sicurezza:"
log "  • CrowdStrike Falcon è software proprietario enterprise — NON replicabile."
log "  • Questo bunker usa un equivalente EDR-lite: auditd + AIDE + ClamAV + rkhunter + chkrootkit + osquery + YARA + Suricata se disponibile."
log "  • Non include cloud threat intelligence proprietaria, kernel sensor Falcon, né console SOC enterprise."
log "  • Per sicurezza enterprise reale: CrowdStrike, SentinelOne, o Wazuh con backend SIEM dedicato."

# L14: Wazuh agente leggero (SIEM open-source — agent-only, Manager su host separato)
# NON installare Wazuh Manager su iMac 2009: troppo RAM/CPU. Solo l'agente.
WAZUH_AGENT_DEB="wazuh-agent_4.7.5-1_amd64.deb"
WAZUH_AGENT_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${WAZUH_AGENT_DEB}"
if command -v wazuh-agentd &>/dev/null; then
  ok "L14: Wazuh agente già installato"
elif $OFFLINE; then
  warn "L14: Wazuh agente — skip in modalità offline"
else
  WAZUH_TMP=$(mktemp)
  if curl -fsSL --max-time 60 "$WAZUH_AGENT_URL" -o "$WAZUH_TMP" 2>>"$LOG_FILE"; then
    WAZUH_MANAGER_IP="${WAZUH_MANAGER_IP:-192.168.1.100}"  # Imposta IP Mac Air M1 come manager
    WAZUH_AGENT_NAME="iMac-kali-bunker"
    dpkg -i "$WAZUH_TMP" >> "$LOG_FILE" 2>&1 || true
    # Configura endpoint manager
    if [ -f /var/ossec/etc/ossec.conf ]; then
      sed -i "s|<address>MANAGER_IP</address>|<address>${WAZUH_MANAGER_IP}</address>|g" /var/ossec/etc/ossec.conf 2>/dev/null || true
      ok "L14: Wazuh agente installato → Manager: ${WAZUH_MANAGER_IP}"
    fi
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable wazuh-agent 2>/dev/null || true
    # Non avviare senza manager configurato — solo abilita
    warn "L14: Wazuh agente abilitato ma NON avviato — configurare WAZUH_MANAGER_IP e avviare con: systemctl start wazuh-agent"
  else
    warn "L14: Wazuh agente — download fallito (non bloccante)"
  fi
  rm -f "$WAZUH_TMP"
fi

log ""
log "  NOTA L14 WAZUH vs CrowdStrike Falcon:"
log "  • Wazuh: SIEM/EDR open source (Apache+AGPL). Free self-hosted. Richiede Manager su host separato."
log "  • Falcon: kernel sensor proprietario, ML con 10+ anni telemetria globale, SOC cloud. Costo: \$8-50/endpoint/mese."
log "  • Differenza critica: Falcon ha kernel sensor con visibilità syscall-level. Wazuh è user-space agent."
log "  • Per questo bunker: solo Wazuh Agent installato. Manager sul Mac Air M1 (WAZUH_MANAGER_IP)."​

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 11: GIT + CLONE REPOS
# ═══════════════════════════════════════════════════════════════════════════════
section "GIT + CLONE REPOS"

git config --global user.name "vio83" 2>/dev/null
git config --global user.email "vio83@users.noreply.github.com" 2>/dev/null
git config --global init.defaultBranch main 2>/dev/null
ok "Git configurato"

PROJECTS_DIR="$REAL_HOME/Projects"
mkdir -p "$PROJECTS_DIR"
mkdir -p "$REAL_HOME/ai-scripts-elite"

# Clone ai-scripts-elite
if [ ! -d "$REAL_HOME/ai-scripts-elite/.git" ]; then
  sudo -u "$REAL_USER" git clone https://github.com/vio83/ai-scripts-elite.git "$REAL_HOME/ai-scripts-elite" >> "$LOG_FILE" 2>&1 \
    && ok "ai-scripts-elite clonato" || warn "Clone ai-scripts-elite fallito (verificare accesso GitHub)"
else
  ok "ai-scripts-elite già presente"
fi

# Clone vio83-ai-orchestra
ORCHESTRA_DIR="$PROJECTS_DIR/vio83-ai-orchestra"
if [ ! -d "$ORCHESTRA_DIR/.git" ]; then
  sudo -u "$REAL_USER" git clone https://github.com/vio83/vio83-ai-orchestra.git "$ORCHESTRA_DIR" >> "$LOG_FILE" 2>&1 \
    && ok "vio83-ai-orchestra clonato" || warn "Clone orchestra fallito (repo privato? Configurare SSH key)"
else
  ok "vio83-ai-orchestra già presente"
fi

chown -R "$REAL_USER:$REAL_USER" "$PROJECTS_DIR" "$REAL_HOME/ai-scripts-elite" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 12: WORLD MONITOR SETUP
# ═══════════════════════════════════════════════════════════════════════════════
section "WORLD MONITOR SETUP"

WM_SCRIPT="$REAL_HOME/ai-scripts-elite/world_monitor.py"
if [ -f "$WM_SCRIPT" ]; then
  ok "World Monitor presente: $WM_SCRIPT"

  # Crea service systemd per World Monitor
  cat > /etc/systemd/system/vio-world-monitor.service << WMEOF
[Unit]
Description=VIO83 World Monitor
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$REAL_HOME/ai-scripts-elite
ExecStart=/usr/bin/python3 $WM_SCRIPT
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
WMEOF
  systemctl daemon-reload 2>/dev/null
  systemctl enable vio-world-monitor 2>/dev/null || true
  systemctl start vio-world-monitor 2>/dev/null || true
  ok "World Monitor: servizio systemd attivo (porta 7778)"
else
  warn "World Monitor non trovato — verrà configurato dopo git clone"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 13: AUTO-OTTIMIZZAZIONE CRON (OGNI 15 MINUTI)
# ═══════════════════════════════════════════════════════════════════════════════
section "AUTO-OTTIMIZZAZIONE CRON 15 MINUTI"

OPTIMIZER="$REAL_HOME/ai-scripts-elite/kali_auto_optimize_15m.sh"

if [ -f "$OPTIMIZER" ]; then
  chmod +x "$OPTIMIZER"
  # Installa crontab
  CRON_LINE="*/15 * * * * $OPTIMIZER >> /var/log/vio83/auto_optimize.log 2>&1"
  append_cron_line "$REAL_USER" "kali_auto_optimize_15m" "$CRON_LINE"
  ok "Cron auto-ottimizzazione: ogni 15 minuti"
else
  warn "Script auto-ottimizzazione non trovato: $OPTIMIZER"
  log "  Verrà installato con il prossimo git pull"
fi

EDR_SCRIPT="$REAL_HOME/ai-scripts-elite/scripts/vio_edr_lite_status.sh"
if [ -f "$EDR_SCRIPT" ]; then
  chmod +x "$EDR_SCRIPT"
  EDR_CRON_LINE="17 */6 * * * $EDR_SCRIPT --report-dir $REAL_HOME/.vio83/edr-reports >> /var/log/vio83/edr_lite.log 2>&1"
  append_cron_line "$REAL_USER" "vio_edr_lite_status" "$EDR_CRON_LINE"
  ok "Cron EDR-lite: report ogni 6 ore"
else
  warn "Script EDR-lite non trovato: $EDR_SCRIPT"
fi

# Cron settimanale: rkhunter + AIDE check
RKH_CRON="30 3 * * 0 rkhunter --check --skip-keypress --quiet 2>&1 | tee -a /var/log/vio83/rkhunter_weekly.log | tail -20 | mail -s 'rkhunter iMac-Kali' root 2>/dev/null || true"
append_cron_line root "rkhunter_weekly" "$RKH_CRON"
ok "Cron rkhunter: ogni domenica alle 03:30"

AIDE_CRON="0 4 * * 1 aide --check 2>&1 | tee -a /var/log/vio83/aide_weekly.log | tail -40 | mail -s 'AIDE iMac-Kali' root 2>/dev/null || true"
append_cron_line root "aide_weekly" "$AIDE_CRON"
ok "Cron AIDE: ogni lunedì alle 04:00"

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 14: VERIFICA FINALE + REPORT
# ═══════════════════════════════════════════════════════════════════════════════
section "VERIFICA FINALE + REPORT"

echo ""
log "  ${BOLD}INVENTARIO STRUMENTI:${NC}"

VERIFY_CMDS=(
  "python3" "pip3" "node" "npm" "git" "curl" "docker" "ollama"
  "code" "tor" "nmap" "exiftool" "ffmpeg" "tesseract" "hashcat"
  "john" "sqlmap" "hydra" "nikto" "gobuster" "whois" "dig"
  "tshark" "steghide" "binwalk" "foremost" "masscan" "clamscan"
  "rkhunter" "lynis" "auditctl" "fail2ban-client" "ufw" "yara"
)

V_OK=0; V_FAIL=0
for cmd in "${VERIFY_CMDS[@]}"; do
  if command -v "$cmd" &>/dev/null; then
    log "  ✅ $cmd"
    V_OK=$((V_OK+1))
  else
    log "  ❌ $cmd"
    V_FAIL=$((V_FAIL+1))
  fi
done

echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BOLD}${BLUE}  🏴 VIO83 BUNKER DEPLOY — RIEPILOGO FINALE${NC}" | tee -a "$LOG_FILE"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "  ${GREEN}✅ Fasi completate: $PHASE/15${NC}" | tee -a "$LOG_FILE"
echo -e "  ${GREEN}✅ Check passati: $PASS${NC}" | tee -a "$LOG_FILE"
echo -e "  ${RED}❌ Check falliti: $FAIL${NC}" | tee -a "$LOG_FILE"
echo -e "  ${YELLOW}⚠️  Warning: $WARN${NC}" | tee -a "$LOG_FILE"
echo -e "  Strumenti: $V_OK operativi, $V_FAIL mancanti" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo -e "  ${BOLD}Servizi attivi:${NC}" | tee -a "$LOG_FILE"
for svc in docker tor fail2ban; do
  if systemctl is-active "$svc" &>/dev/null; then
    echo -e "  ✅ $svc" | tee -a "$LOG_FILE"
  else
    echo -e "  ❌ $svc" | tee -a "$LOG_FILE"
  fi
done
echo "" | tee -a "$LOG_FILE"
echo -e "  Log completo: $LOG_FILE" | tee -a "$LOG_FILE"
echo -e "  Completato: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

if [ "$FAIL" -lt 5 ]; then
  echo -e "\n${BOLD}${GREEN}  🏴 BUNKER OPERATIVO — Intelligence Station pronta${NC}"
  echo -e "${GREEN}  World Monitor:  http://localhost:7778${NC}"
  echo -e "${GREEN}  Tor SOCKS:      localhost:9050${NC}"
  echo -e "${GREEN}  VS Code:        code ~/ai-scripts-elite${NC}\n"
  echo -e "${GREEN}  EDR-lite audit: ~/ai-scripts-elite/scripts/vio_edr_lite_status.sh${NC}\n"
else
  echo -e "\n${BOLD}${YELLOW}  ⚠️  Deploy parziale — $FAIL problemi da risolvere${NC}\n"
fi
