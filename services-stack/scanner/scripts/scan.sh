#!/bin/bash
# scan.sh — Action script triggered by scanbd on button press
#
# Environment (set by scanbd):
#   SCANBD_DEVICE  — SANE device URI
#   SCANBD_ACTION  — Action name (scan, copy, email, pdf, fax)
#
# Environment (set in docker-compose):
#   SCAN_DPI       — Resolution (default: 300)
#   OUTPUT_DIR     — Output directory (default: /output)
#   ADF_SOURCE     — SANE source for simplex (default: ADF)
#   ADF_DUPLEX_SRC — SANE source for duplex  (default: "ADF Duplex")

set -uo pipefail

# ── Configuration ──────────────────────────────────────
SCAN_DPI="${SCAN_DPI:-300}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
ADF_SOURCE="${ADF_SOURCE:-ADF}"
ADF_DUPLEX_SRC="${ADF_DUPLEX_SRC:-ADF Duplex}"
DEVICE="${SCANBD_DEVICE:-}"

# Read persistent color mode toggle
COLOR_MODE_FILE="/etc/scanbd/color_mode"
DEFAULT_COLOR="Color"
if [ -f "$COLOR_MODE_FILE" ]; then
    DEFAULT_COLOR=$(cat "$COLOR_MODE_FILE" 2>/dev/null || echo "Color")
fi

# ── Determine scan mode from button action ─────────────
case "${SCANBD_ACTION:-scan}" in
    scan)
        DUPLEX="off"
        COLOR="$DEFAULT_COLOR"
        ;;
    copy|fax)
        DUPLEX="on"
        COLOR="$DEFAULT_COLOR"
        ;;
    email)
        DUPLEX="off"
        COLOR="Gray"
        ;;
    pdf)
        DUPLEX="on"
        COLOR="Gray"
        ;;
    *)
        DUPLEX="off"
        COLOR="$DEFAULT_COLOR"
        ;;
esac

# Determine ADF source
if [ "$DUPLEX" = "on" ]; then
    SOURCE="$ADF_DUPLEX_SRC"
else
    SOURCE="$ADF_SOURCE"
fi

# ── Prepare temp directory ─────────────────────────────
TEMP_DIR=$(mktemp -d /tmp/scan_XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="scan_${TIMESTAMP}"

echo "=========================================="
echo "  Scan triggered: $(date)"
echo "  Device:  ${DEVICE:-auto-detect}"
echo "  Action:  ${SCANBD_ACTION:-manual}"
echo "  Source:  ${SOURCE}"
echo "  Color:   ${COLOR}"
echo "  DPI:     ${SCAN_DPI}"
echo "  Duplex:  ${DUPLEX}"
echo "=========================================="

# ── Perform scan ───────────────────────────────────────
SCAN_ARGS=(
    --resolution="${SCAN_DPI}"
    --mode="${COLOR}"
    --format=tiff
    --batch="${TEMP_DIR}/page_%04d.tiff"
    --batch-count=0
    --source="${SOURCE}"
)

if [ -n "$DEVICE" ]; then
    SCAN_ARGS=(--device-name="${DEVICE}" "${SCAN_ARGS[@]}")
fi

# scanimage exits non-zero when ADF runs out of paper — this is expected
scanimage "${SCAN_ARGS[@]}" 2>&1 || true

# ── Check results ──────────────────────────────────────
PAGE_COUNT=$(find "$TEMP_DIR" -maxdepth 1 -name "page_*.tiff" 2>/dev/null | wc -l)
if [ "$PAGE_COUNT" -eq 0 ]; then
    echo "⚠ No pages scanned. Check paper in ADF."
    exit 0
fi

echo "✓ Scanned ${PAGE_COUNT} page(s)"

# ── Convert to PDF ─────────────────────────────────────
# Sort files naturally to maintain correct page order
find "$TEMP_DIR" -maxdepth 1 -name "page_*.tiff" | sort -V | \
    xargs img2pdf -o "${TEMP_DIR}/${FILENAME}.pdf" 2>&1

# Move final PDF to output (Paperless-ngx handles OCR)
cp "${TEMP_DIR}/${FILENAME}.pdf" "${OUTPUT_DIR}/${FILENAME}.pdf"

echo "=========================================="
echo "  ✓ Saved: ${OUTPUT_DIR}/${FILENAME}.pdf"
echo "    Pages: ${PAGE_COUNT}"
echo "=========================================="
