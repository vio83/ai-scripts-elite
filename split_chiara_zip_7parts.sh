#!/bin/bash
set -euo pipefail

# Split di chiara.zip in 7 parti nominative per invio email
# ATTENZIONE: i file chiara1.zip..chiara7.zip NON sono zip indipendenti,
# sono parti binarie da ricomporre prima dell'uso.

SOURCE_ZIP="${1:-$HOME/Pictures/chiara.zip}"
OUT_DIR="${2:-$HOME/Pictures/chiara_split}"
PARTS=7
BASENAME="chiara"

if [ ! -f "$SOURCE_ZIP" ]; then
  echo "Errore: file sorgente non trovato: $SOURCE_ZIP"
  exit 1
fi

mkdir -p "$OUT_DIR"

TOTAL_BYTES=$(stat -f%z "$SOURCE_ZIP")
PART_SIZE=$(( (TOTAL_BYTES + PARTS - 1) / PARTS ))

echo "Sorgente: $SOURCE_ZIP"
echo "Dimensione totale: $TOTAL_BYTES byte"
echo "Parti: $PARTS"
echo "Dimensione target per parte: $PART_SIZE byte"
echo "Output: $OUT_DIR"

tmp_prefix="$OUT_DIR/${BASENAME}.part."
rm -f "$tmp_prefix"*

# Split binario in 7 parti
split -b "$PART_SIZE" -d -a 2 "$SOURCE_ZIP" "$tmp_prefix"

# Rinomina in chiara1.zip ... chiara7.zip
idx=1
for f in "$tmp_prefix"*; do
  mv "$f" "$OUT_DIR/${BASENAME}${idx}.zip"
  idx=$((idx + 1))
done

# Verifica conteggio
COUNT=$(ls -1 "$OUT_DIR"/${BASENAME}[1-7].zip 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -ne 7 ]; then
  echo "Errore: numero parti generate diverso da 7 (trovate: $COUNT)"
  exit 1
fi

echo ""
echo "OK: generate le 7 parti:"
ls -lh "$OUT_DIR"/${BASENAME}[1-7].zip

echo ""
echo "Per ricomporre sull'altro Mac/iMac:"
echo "cat ${BASENAME}1.zip ${BASENAME}2.zip ${BASENAME}3.zip ${BASENAME}4.zip ${BASENAME}5.zip ${BASENAME}6.zip ${BASENAME}7.zip > ${BASENAME}_rebuild.zip"
echo ""
echo "Verifica integrita dopo ricostruzione:"
echo "unzip -t ${BASENAME}_rebuild.zip"
