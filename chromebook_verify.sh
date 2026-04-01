#!/usr/bin/env bash

echo "=== VERIFICA CHROMEBOOK SUITE ==="
echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo "--- SISTEMA ---"
uname -a 2>/dev/null || echo "uname: FAIL"
cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || echo "os-release: FAIL"
echo ""

echo "--- SPAZIO DISCO ---"
df -h / 2>/dev/null || echo "df: FAIL"
echo ""

echo "--- MEMORIA ---"
free -h 2>/dev/null || echo "free: FAIL"
echo ""

echo "--- PACCHETTI INSTALLATI ---"
for cmd in curl wget git rsync jq htop tmux python3 nmap tcpdump tshark sqlmap hydra john hashcat sha256sum; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  $cmd: OK"
  else
    echo "  $cmd: MANCANTE"
  fi
done
echo ""

echo "--- OPENTIMESTAMPS ---"
export PATH="$HOME/.local/bin:$PATH"
if command -v ots >/dev/null 2>&1; then
  echo "  ots: OK ($(command -v ots))"
else
  echo "  ots: NON INSTALLATO"
fi
echo ""

echo "--- OUTPUT PRECEDENTI ---"
echo "chromebook_suite_*:"
ls -d "$HOME"/chromebook_suite_* 2>/dev/null || echo "  nessuno trovato"
echo ""
echo "crostini_stability_*:"
ls -d "$HOME"/crostini_stability_* 2>/dev/null || echo "  nessuno trovato"
echo ""
echo "bitcoin_proof_*:"
ls -d "$HOME"/bitcoin_proof_* 2>/dev/null || echo "  nessuno trovato"
echo ""
echo "security_toolchain_*:"
ls -d "$HOME"/security_toolchain_* 2>/dev/null || echo "  nessuno trovato"
echo ""

echo "--- FILE HASH/PROOF ---"
for d in "$HOME"/chromebook_suite_* "$HOME"/bitcoin_proof_*; do
  if [ -d "$d" ]; then
    echo "  $d:"
    ls -la "$d"/ 2>/dev/null
    if [ -f "$d/master_hash.txt" ]; then
      echo "  Master Hash: $(cat "$d/master_hash.txt")"
    fi
    if [ -f "$d/hash_of_hashes.txt" ]; then
      echo "  Hash of Hashes: $(cat "$d/hash_of_hashes.txt")"
    fi
    echo ""
  fi
done

echo "=== FINE VERIFICA ==="
