#!/usr/bin/env bash
set -Eeuo pipefail

echo "[=== CHROMEBOOK FINISH INSTALL ===]"
echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.local/bin:/usr/sbin:$PATH"

OUT_BASE="$HOME/chromebook_finish_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_BASE"
LOG="$OUT_BASE/finish.log"
exec > >(tee -a "$LOG") 2>&1

echo "[STEP] Preseed tshark/wireshark per evitare dialog bloccanti"
if command -v debconf-set-selections >/dev/null 2>&1; then
  printf '%s\n' 'wireshark-common wireshark-common/install-setuid boolean false' | sudo debconf-set-selections || true
fi

echo "[STEP] Completo i pacchetti mancanti senza prompt"
sudo -E apt-get update
sudo -E apt-get -y install \
  python3 python3-pip python3-setuptools python3-wheel python3-dev build-essential \
  nmap tcpdump tshark sqlmap hydra john hashcat || true

echo "[STEP] Installo OpenTimestamps da PyPI"
if ! python3 -m pip install --user --upgrade pip setuptools wheel --break-system-packages; then
  python3 -m pip install --user --upgrade pip setuptools wheel || true
fi

if ! python3 -m pip install --user opentimestamps-client --break-system-packages; then
  python3 -m pip install --user opentimestamps-client || true
fi

echo "[STEP] Verifica binari"
for cmd in nmap tcpdump tshark sqlmap hydra john hashcat ots; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd: OK ($(command -v "$cmd"))"
  else
    echo "$cmd: MISSING"
  fi
done

# In Debian Bookworm il binario john può essere in /usr/sbin, spesso fuori PATH utente.
if [ -x /usr/sbin/john ] && ! command -v john >/dev/null 2>&1; then
  ln -sf /usr/sbin/john "$HOME/.local/bin/john" || true
fi

echo "[STEP] Cerco l'ultimo hash_of_hashes.txt gia generato"
LATEST_HOH="$(find "$HOME" -maxdepth 2 -type f -name 'hash_of_hashes.txt' | sort | tail -n 1)"
if [ -z "$LATEST_HOH" ]; then
  echo "[WARN] Nessun hash_of_hashes.txt trovato. Installazione completata, ma nessuna prova OTS da eseguire."
  exit 0
fi

echo "[INFO] Uso: $LATEST_HOH"

OTS_FILE="$LATEST_HOH.ots"
OTS_STAMP="skipped_existing"
OTS_VERIFY="pending"

if [ -f "$OTS_FILE" ]; then
  echo "[STEP] Timestamp OTS già presente, salto stamp"
else
  echo "[STEP] Creo timestamp OTS"
  ots stamp "$LATEST_HOH"
  OTS_STAMP="ok"
fi

if [ -f "$OTS_FILE" ]; then
  echo "[STEP] Upgrade OTS"
  ots upgrade "$OTS_FILE" || true

  echo "[STEP] Verify OTS"
  if ots verify "$OTS_FILE" >/dev/null 2>&1; then
    OTS_VERIFY="confirmed"
  fi
fi

REPORT="$OUT_BASE/final_report.md"
{
  echo "# Chromebook Finish Install Report"
  echo
  echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Hash file: $LATEST_HOH"
  echo "OTS file: $OTS_FILE"
  echo "OTS stamp: $OTS_STAMP"
  echo "OTS verify: $OTS_VERIFY"
} > "$REPORT"

echo "[DONE] Completamento eseguito"
echo "[OUTPUT] $OUT_BASE"
echo "[REPORT] $REPORT"
if [ "$OTS_VERIFY" != "confirmed" ]; then
  echo "[NEXT] Ripetere tra alcune ore:"
  echo "export PATH=\$HOME/.local/bin:\$PATH"
  echo "ots upgrade '$OTS_FILE'"
  echo "ots verify '$OTS_FILE'"
fi
