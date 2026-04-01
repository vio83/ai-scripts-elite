#!/usr/bin/env bash
# ============================================================
# KALI LINUX DEV SETUP — VIO AI Orchestra
# Target: iMac 27" Late 2009 (iMac11,1) — Kali Live Boot
# Autore: vio83
# Data: 2026-04-01
# Stack: Python + FastAPI | Node.js + React/Vite | Git | Ollama
# ============================================================
# ATTENZIONE: Kali Live = ambiente in RAM.
# Tutto ciò che si installa viene perso al reboot.
# Usare per sessioni di lavoro; per persistenza → installazione SSD.
# ============================================================

set -euo pipefail

# ── Colori ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="/tmp/kali_dev_setup_$(date +%Y%m%d_%H%M%S).log"

log()   { echo -e "${GREEN}[✓]${NC} $1"; echo "[$(date +%H:%M:%S)] OK: $1" >> "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; echo "[$(date +%H:%M:%S)] WARN: $1" >> "$LOG_FILE"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; echo "[$(date +%H:%M:%S)] FAIL: $1" >> "$LOG_FILE"; }
header(){ echo -e "\n${CYAN}── $1 ──${NC}"; }

# ── Prerequisiti ───────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Eseguire come root: sudo bash $0${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   VIO AI Orchestra — Kali Dev Environment Setup        ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "Target: iMac 27\" 2009 (i7, 8GB RAM)"
echo -e "Stack:  Python/FastAPI + Node.js/React + Ollama"
echo -e "Log:    ${LOG_FILE}"
echo ""

ERRORS=0
track_error() { ERRORS=$((ERRORS + 1)); fail "$1"; }

# ═══════════════════════════════════════════════════════════
# FASE 0: SICUREZZA TERMICA (NON NEGOZIABILE)
# ═══════════════════════════════════════════════════════════
header "FASE 0 — Controllo termico iMac"

if command -v macfanctld >/dev/null 2>&1; then
    log "macfanctld già presente"
else
    warn "macfanctld non trovato — installazione in corso..."
    if apt-get install -y macfanctld >> "$LOG_FILE" 2>&1; then
        log "macfanctld installato"
    else
        warn "macfanctld non disponibile nei repo — tentativo manuale"
        # Fallback: imposta ventole al massimo via applesmc
        APPLESMC="/sys/devices/platform/applesmc.0"
        if [ -d "$APPLESMC" ]; then
            for fan_manual in "$APPLESMC"/fan*_manual; do
                [ -f "$fan_manual" ] && echo 1 > "$fan_manual" 2>/dev/null || true
            done
            for fan_output in "$APPLESMC"/fan*_output; do
                [ -f "$fan_output" ] && echo 6000 > "$fan_output" 2>/dev/null || true
            done
            log "Ventole impostate al massimo via applesmc (fallback)"
        else
            warn "applesmc non trovato — MONITORA LE TEMPERATURE MANUALMENTE"
        fi
    fi
fi

# Avvia macfanctld se installato e non già in esecuzione
if command -v macfanctld >/dev/null 2>&1; then
    if ! pgrep -x macfanctld >/dev/null 2>&1; then
        macfanctld &
        log "macfanctld avviato in background"
    else
        log "macfanctld già in esecuzione"
    fi
fi

# ═══════════════════════════════════════════════════════════
# FASE 1: AGGIORNAMENTO REPOSITORY
# ═══════════════════════════════════════════════════════════
header "FASE 1 — Aggiornamento repository apt"

if apt-get update >> "$LOG_FILE" 2>&1; then
    log "Repository aggiornati"
else
    track_error "apt-get update fallito — verificare connessione di rete"
fi

# ═══════════════════════════════════════════════════════════
# FASE 2: STRUMENTI BASE E BUILD
# ═══════════════════════════════════════════════════════════
header "FASE 2 — Strumenti base e compilazione"

BASE_PKGS=(
    build-essential
    curl
    wget
    git
    jq
    htop
    tmux
    unzip
    ca-certificates
    gnupg
    lsb-release
    pkg-config
    libssl-dev
    libffi-dev
)

for pkg in "${BASE_PKGS[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "$pkg già installato"
    else
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            log "$pkg installato"
        else
            track_error "$pkg — installazione fallita"
        fi
    fi
done

# ═══════════════════════════════════════════════════════════
# FASE 3: PYTHON DEVELOPMENT
# ═══════════════════════════════════════════════════════════
header "FASE 3 — Python environment"

PY_PKGS=(
    python3-full
    python3-pip
    python3-venv
    python3-dev
)

for pkg in "${PY_PKGS[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "$pkg già installato"
    else
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            log "$pkg installato"
        else
            track_error "$pkg — installazione fallita"
        fi
    fi
done

# Crea virtualenv per VIO AI Orchestra
VIO_VENV="/root/vio-orchestra-env"
if [ ! -d "$VIO_VENV" ]; then
    python3 -m venv "$VIO_VENV" 2>> "$LOG_FILE"
    log "Virtualenv creato: $VIO_VENV"
else
    log "Virtualenv già presente: $VIO_VENV"
fi

# Installa dipendenze Python nello venv
"$VIO_VENV/bin/pip" install --upgrade pip >> "$LOG_FILE" 2>&1

PY_DEPS=(
    fastapi
    uvicorn
    httpx
    psutil
    pydantic
    python-dotenv
    flask
)

for dep in "${PY_DEPS[@]}"; do
    if "$VIO_VENV/bin/pip" install "$dep" >> "$LOG_FILE" 2>&1; then
        log "pip: $dep installato"
    else
        track_error "pip: $dep — installazione fallita"
    fi
done

# ═══════════════════════════════════════════════════════════
# FASE 4: NODE.JS + NPM
# ═══════════════════════════════════════════════════════════
header "FASE 4 — Node.js LTS"

if command -v node >/dev/null 2>&1; then
    NODE_VER=$(node --version 2>/dev/null || echo "sconosciuta")
    log "Node.js già presente: $NODE_VER"
else
    # NodeSource LTS (Node 22.x)
    NODE_MAJOR=22
    KEYRING_DIR="/etc/apt/keyrings"
    mkdir -p "$KEYRING_DIR"

    if curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
        | gpg --dearmor -o "$KEYRING_DIR/nodesource.gpg" 2>> "$LOG_FILE"; then

        echo "deb [signed-by=$KEYRING_DIR/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
            > /etc/apt/sources.list.d/nodesource.list

        apt-get update >> "$LOG_FILE" 2>&1
        if apt-get install -y nodejs >> "$LOG_FILE" 2>&1; then
            log "Node.js $(node --version) installato"
        else
            track_error "Node.js — installazione da NodeSource fallita"
        fi
    else
        track_error "NodeSource GPG key — download fallito"
    fi
fi

# Verifica npm
if command -v npm >/dev/null 2>&1; then
    log "npm $(npm --version) presente"
else
    track_error "npm non disponibile"
fi

# ═══════════════════════════════════════════════════════════
# FASE 5: GIT CONFIG
# ═══════════════════════════════════════════════════════════
header "FASE 5 — Configurazione Git"

# Configurazione base per sessione Live (non persistente)
git config --global user.name "vio83" 2>/dev/null
git config --global user.email "vio83@users.noreply.github.com" 2>/dev/null
git config --global init.defaultBranch main 2>/dev/null
git config --global core.editor nano 2>/dev/null
log "Git configurato (user: vio83, branch default: main)"

# ═══════════════════════════════════════════════════════════
# FASE 6: STRUMENTI ADDIZIONALI VIO AI ORCHESTRA
# ═══════════════════════════════════════════════════════════
header "FASE 6 — Strumenti addizionali"

# Editor e utility
EXTRA_PKGS=(
    nano
    tree
    net-tools
    openssh-client
    rsync
)

for pkg in "${EXTRA_PKGS[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "$pkg già installato"
    else
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            log "$pkg installato"
        else
            track_error "$pkg — installazione fallita"
        fi
    fi
done

# ═══════════════════════════════════════════════════════════
# FASE 7: OLLAMA (AI LOCALE)
# ═══════════════════════════════════════════════════════════
header "FASE 7 — Ollama (AI locale)"

if command -v ollama >/dev/null 2>&1; then
    log "Ollama già presente: $(ollama --version 2>/dev/null || echo 'installato')"
else
    warn "Installazione Ollama..."
    OLLAMA_TMP=$(mktemp)
    if curl -fsSL "https://ollama.com/install.sh" -o "$OLLAMA_TMP" 2>> "$LOG_FILE"; then
        if bash "$OLLAMA_TMP" >> "$LOG_FILE" 2>&1; then
            log "Ollama installato"
        else
            track_error "Ollama — installazione fallita"
        fi
        rm -f "$OLLAMA_TMP"
    else
        track_error "Ollama — download script fallito"
        rm -f "$OLLAMA_TMP"
    fi
fi

# ═══════════════════════════════════════════════════════════
# FASE 8: WORKSPACE DIRECTORY
# ═══════════════════════════════════════════════════════════
header "FASE 8 — Directory workspace"

WORKSPACE="/root/Projects/vio83-ai-orchestra"
mkdir -p "$WORKSPACE"
log "Workspace pronto: $WORKSPACE"

# Crea file .env template (senza segreti)
if [ ! -f "$WORKSPACE/.env" ]; then
    cat > "$WORKSPACE/.env" <<'ENVEOF'
# VIO AI Orchestra — Environment Variables
# NON committare questo file — solo .env.example va nel repo
OLLAMA_HOST=http://localhost:11434
VITE_API_URL=http://localhost:8000
FASTAPI_PORT=8000
ENVEOF
    log ".env template creato"
fi

# Crea .env.example (committabile)
if [ ! -f "$WORKSPACE/.env.example" ]; then
    cat > "$WORKSPACE/.env.example" <<'ENVEOF'
# VIO AI Orchestra — Environment Variables Template
OLLAMA_HOST=http://localhost:11434
VITE_API_URL=http://localhost:8000
FASTAPI_PORT=8000
ENVEOF
    log ".env.example creato"
fi

# ═══════════════════════════════════════════════════════════
# FASE 9: VERIFICA FINALE
# ═══════════════════════════════════════════════════════════
header "FASE 9 — Verifica installazione"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   REPORT INSTALLAZIONE                                ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_tool() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        local ver
        ver=$("$cmd" --version 2>/dev/null | head -1 || echo "presente")
        echo -e "  ${GREEN}✓${NC} $name: $ver"
    else
        echo -e "  ${RED}✗${NC} $name: NON TROVATO"
    fi
}

check_tool "Python3"    python3
check_tool "pip3"       pip3
check_tool "Node.js"    node
check_tool "npm"        npm
check_tool "Git"        git
check_tool "curl"       curl
check_tool "tmux"       tmux
check_tool "htop"       htop
check_tool "jq"         jq

echo ""
echo -e "  ${BOLD}Virtualenv:${NC} $VIO_VENV"
if [ -f "$VIO_VENV/bin/python" ]; then
    echo -e "  ${GREEN}✓${NC} Python venv attivo"
    echo -e "  ${GREEN}✓${NC} FastAPI: $("$VIO_VENV/bin/pip" show fastapi 2>/dev/null | grep Version || echo 'installato')"
else
    echo -e "  ${RED}✗${NC} Virtualenv non valido"
fi

echo ""
if command -v ollama >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Ollama installato"
else
    echo -e "  ${YELLOW}!${NC} Ollama non disponibile"
fi

# Controllo termico finale
echo ""
if pgrep -x macfanctld >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} macfanctld: IN ESECUZIONE"
else
    echo -e "  ${YELLOW}!${NC} macfanctld: NON ATTIVO — monitorare temperature"
fi

# ═══════════════════════════════════════════════════════════
# RIEPILOGO
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}   SETUP COMPLETATO — 0 errori${NC}"
else
    echo -e "${YELLOW}${BOLD}   SETUP COMPLETATO CON $ERRORS ERRORE/I${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Prossimi passi:${NC}"
echo -e "  1. Attiva venv:  ${CYAN}source $VIO_VENV/bin/activate${NC}"
echo -e "  2. Clona repo:   ${CYAN}cd $WORKSPACE && git clone https://github.com/vio83/vio83-ai-orchestra.git .${NC}"
echo -e "  3. Avvia Ollama:  ${CYAN}ollama serve &${NC}"
echo -e "  4. Pull modello:  ${CYAN}ollama pull llama3.2:1b${NC}"
echo ""
echo -e "  Log completo: ${LOG_FILE}"
echo ""
echo -e "${YELLOW}  ⚠ RICORDA: Kali Live = tutto in RAM. Al reboot si perde.${NC}"
echo ""
