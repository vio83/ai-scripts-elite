#!/usr/bin/env bash
set -Eeuo pipefail

echo "[=== CHROMEBOOK COMPLETE SUITE ===]"
echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

OUT_BASE="$HOME/chromebook_suite_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_BASE"
LOG="$OUT_BASE/main.log"
exec > >(tee -a "$LOG") 2>&1

echo "[PHASE 1] Baseline Crostini"
echo "Output: $OUT_BASE"

if [ ! -f /etc/os-release ]; then
  echo "[ERROR] Non sei in Linux Crostini"
  exit 1
fi

cat /etc/os-release
uname -a
free -h
df -h

free_gb="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4+0}')"
if [ "$free_gb" -lt 10 ]; then
  echo "[ERROR] Spazio insufficiente: ${free_gb}GB < 10GB"
  exit 1
fi

echo "[STEP] Aggiornamento sistema"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade
sudo apt-get -y autoremove --purge
sudo apt-get -y autoclean

echo "[STEP] Pacchetti base"
sudo apt-get install -y ca-certificates curl wget gnupg git rsync jq htop tmux python3 python3-pip || true

echo "[STEP] Pacchetti security"
sudo apt-get install -y nmap tcpdump tshark sqlmap hydra john hashcat || true

echo "[PHASE 2] OpenTimestamps install"
OTS_OK="no"

if command -v ots >/dev/null 2>&1; then
  OTS_OK="yes_already"
else
  sudo apt-get install -y opentimestamps-client 2>/dev/null || true
  sudo apt-get install -y opentimestamps 2>/dev/null || true
fi

if command -v ots >/dev/null 2>&1; then
  OTS_OK="yes_apt"
else
  python3 -m pip install --user --upgrade pip 2>/dev/null || true
  python3 -m pip install --user opentimestamps-client 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
  if command -v ots >/dev/null 2>&1; then
    OTS_OK="yes_pip"
  fi
fi

echo "OTS status: $OTS_OK"

echo "[PHASE 3] Hash + Bitcoin Proof"
TARGET="${1:-$HOME/Documents}"

if [ ! -e "$TARGET" ]; then
  echo "[WARN] Target non trovato: $TARGET - uso HOME"
  TARGET="$HOME"
fi

REG="$OUT_BASE/hash_registry.txt"
MASTER="$OUT_BASE/master_hash.txt"
HOH="$OUT_BASE/hash_of_hashes.txt"

echo "[STEP] Hash registry locale"
if [ -f "$TARGET" ]; then
  sha256sum "$TARGET" > "$REG"
else
  find "$TARGET" -maxdepth 3 -type f ! -path "*/.git/*" -print0 2>/dev/null | sort -z | xargs -0 sha256sum > "$REG" 2>/dev/null || true
fi

echo "[STEP] Master hash"
MHASH="$(sha256sum "$REG" | awk '{print $1}')"
echo "$MHASH" > "$MASTER"

echo "[STEP] Hash of hashes"
HHASH="$(sha256sum "$MASTER" | awk '{print $1}')"
echo "$HHASH" > "$HOH"

echo "Master Hash: $MHASH"
echo "Hash of Hashes: $HHASH"

OTS_STAMP="skipped"
OTS_VERIFY="skipped"

if command -v ots >/dev/null 2>&1; then
  echo "[STEP] OTS stamp"
  if ots stamp "$HOH" 2>/dev/null; then
    OTS_STAMP="ok"
    if [ -f "$HOH.ots" ]; then
      echo "[STEP] OTS upgrade"
      ots upgrade "$HOH.ots" 2>/dev/null || true
      echo "[STEP] OTS verify"
      if ots verify "$HOH.ots" >/dev/null 2>&1; then
        OTS_VERIFY="confirmed"
      else
        OTS_VERIFY="pending"
      fi
    fi
  else
    OTS_STAMP="failed"
  fi
else
  echo "[INFO] OTS non disponibile - hash generati comunque"
fi

REPORT="$OUT_BASE/final_report.md"
echo "# Chromebook Suite Report" > "$REPORT"
echo "" >> "$REPORT"
echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$REPORT"
echo "Target: $TARGET" >> "$REPORT"
echo "Output: $OUT_BASE" >> "$REPORT"
echo "" >> "$REPORT"
echo "## Hash Evidence" >> "$REPORT"
echo "Master Hash: $MHASH" >> "$REPORT"
echo "Hash of Hashes: $HHASH" >> "$REPORT"
echo "" >> "$REPORT"
echo "## OpenTimestamps" >> "$REPORT"
echo "Install: $OTS_OK" >> "$REPORT"
echo "Stamp: $OTS_STAMP" >> "$REPORT"
echo "Verify: $OTS_VERIFY" >> "$REPORT"

echo ""
echo "[DONE] Suite completata"
echo "[OUTPUT] $OUT_BASE"
echo "[REPORT] $REPORT"
echo ""
echo "Se OTS e pending, ripeti tra qualche ora:"
echo "  export PATH=\$HOME/.local/bin:\$PATH"
echo "  ots upgrade $HOH.ots"
echo "  ots verify $HOH.ots"
