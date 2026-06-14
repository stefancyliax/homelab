#!/bin/bash
# scan-flatbed.sh — Scan a single page from the flatbed glass
#
# Usage:
#   docker exec scanner scan-flatbed
#
# Uses the current color mode toggle (toggle-color).
# Flatbed is always single-sided (duplex toggle is ignored).

set -uo pipefail

SCAN_DPI="${FLATBED_DPI:-600}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
STATE_DIR="/var/lib/scanner"

COLOR=$(cat "$STATE_DIR/color_mode" 2>/dev/null || echo "Color")

# Auto-detect scanner device
DEVICE=$(scanimage -L 2>/dev/null | grep 'airscan' | head -1 | sed "s/.*\`//" | sed "s/'.*//")
if [ -z "$DEVICE" ]; then
    echo "⚠ No scanner found"
    exit 1
fi

TEMP_DIR=$(mktemp -d /tmp/scan_XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="scan_${TIMESTAMP}"

echo "Flatbed scan starting..."
echo "  Device:  ${DEVICE}"
echo "  Color:   ${COLOR}"
echo "  DPI:     ${SCAN_DPI}"

scanimage \
    --device-name="${DEVICE}" \
    --resolution="${SCAN_DPI}" \
    --mode="${COLOR}" \
    --source=Flatbed \
    --format=tiff \
    -x 215.9 \
    -y 297.18 \
    -o "${TEMP_DIR}/page.tiff" 2>&1

if [ ! -f "${TEMP_DIR}/page.tiff" ]; then
    echo "⚠ Scan failed — no output"
    exit 1
fi

img2pdf --pillow-limit-break -o "${TEMP_DIR}/${FILENAME}.pdf" "${TEMP_DIR}/page.tiff" 2>&1 | \
    grep -v "DecompressionBomb\|warnings.warn" || true

cp "${TEMP_DIR}/${FILENAME}.pdf" "${OUTPUT_DIR}/${FILENAME}.pdf"

echo "✓ Saved: ${FILENAME}.pdf"
