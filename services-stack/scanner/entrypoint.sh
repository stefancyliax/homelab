#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║  HP ScanJet Pro 2600 f1 Scanner          ║"
echo "║  $(date '+%Y-%m-%d %H:%M:%S')                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Diagnostics ────────────────────────────────────────
echo "USB devices:"
lsusb 2>/dev/null | grep -iE "hp|scan|03f0" | sed 's/^/  /' || echo "  ⚠ No HP scanner found on USB"

echo ""
echo "SANE detection:"
scanimage -L 2>&1 | sed 's/^/  /' || echo "  ⚠ No SANE devices found"

echo ""
echo "Configuration:"
echo "  Color mode:  $(cat /etc/scanbd/color_mode 2>/dev/null || echo 'Color')"
echo "  DPI:         ${SCAN_DPI:-300}"
echo "  Output:      /output"
echo ""
echo "Commands:"
echo "  docker exec scanner test-buttons    # discover buttons"
echo "  docker exec scanner toggle-color    # switch Color/Gray"
echo ""
echo "Starting scanbd (debug-level=${SCANBD_DEBUG:-2})..."
echo "────────────────────────────────────────────"

# ── Start scanbd in standalone foreground mode ─────────
# scanbd polls scanner buttons and triggers scan.sh on press.
# It releases the SANE device before calling the script,
# allowing scanimage to access the scanner for scanning.
exec scanbd -f -d"${SCANBD_DEBUG:-2}" -c /etc/scanbd/scanbd.conf
