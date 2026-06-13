#!/bin/bash
# scan.sh — Scan all ADF pages and save as timestamped PDF
#
# Reads scan settings from toggle files and environment:
#   /var/lib/scanner/color_mode   — "Color" or "Gray"
#   /var/lib/scanner/duplex_mode  — "on" or "off"
#   SCAN_DPI                      — resolution (default: 300)
#   OUTPUT_DIR                    — output directory (default: /output)

set -uo pipefail

# ── Configuration ──────────────────────────────────────
SCAN_DPI="${SCAN_DPI:-300}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
STATE_DIR="/var/lib/scanner"

# Read persistent toggle modes
COLOR=$(cat "$STATE_DIR/color_mode" 2>/dev/null || echo "Color")
DUPLEX=$(cat "$STATE_DIR/duplex_mode" 2>/dev/null || echo "off")

# Determine ADF source
if [ "$DUPLEX" = "on" ]; then
    SOURCE="ADF Duplex"
else
    SOURCE="ADF"
fi

# Auto-detect scanner device
DEVICE=$(scanimage -L 2>/dev/null | grep 'airscan' | head -1 | sed "s/.*\`//" | sed "s/'.*//")
if [ -z "$DEVICE" ]; then
    echo "⚠ No scanner found"
    exit 1
fi

# ── Prepare temp directory ─────────────────────────────
TEMP_DIR=$(mktemp -d /tmp/scan_XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="scan_${TIMESTAMP}"

echo "  Device:  ${DEVICE}"
echo "  Source:  ${SOURCE}"
echo "  Color:   ${COLOR}"
echo "  DPI:     ${SCAN_DPI}"

# ── Perform scan ───────────────────────────────────────
SCAN_ARGS=(
    --device-name="${DEVICE}"
    --resolution="${SCAN_DPI}"
    --mode="${COLOR}"
    --format=tiff
    --batch="${TEMP_DIR}/page_%04d.tiff"
    --batch-count=0
    --source="${SOURCE}"
)

# scanimage exits non-zero when ADF runs out of paper — this is expected
scanimage "${SCAN_ARGS[@]}" 2>&1 || true

# ── Check results ──────────────────────────────────────
PAGE_COUNT=$(find "$TEMP_DIR" -maxdepth 1 -name "page_*.tiff" 2>/dev/null | wc -l)
if [ "$PAGE_COUNT" -eq 0 ]; then
    echo "  ⚠ No pages scanned"
    exit 1
fi

echo "  ✓ Scanned ${PAGE_COUNT} page(s)"

# ── Convert to PDF ─────────────────────────────────────
find "$TEMP_DIR" -maxdepth 1 -name "page_*.tiff" | sort -V | \
    xargs img2pdf -o "${TEMP_DIR}/${FILENAME}.pdf" 2>&1

# Move final PDF to output (Paperless-ngx handles OCR)
cp "${TEMP_DIR}/${FILENAME}.pdf" "${OUTPUT_DIR}/${FILENAME}.pdf"

echo "  ✓ Saved: ${FILENAME}.pdf (${PAGE_COUNT} pages)"
