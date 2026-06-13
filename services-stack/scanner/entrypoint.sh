#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║  HP ScanJet Pro 2600 f1 Scanner          ║"
echo "║  $(date '+%Y-%m-%d %H:%M:%S')                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Start ipp-usb (USB → HTTP bridge) ─────────────────
echo "Starting ipp-usb..."
mkdir -p /var/run/ipp-usb
ipp-usb standalone &
IPP_USB_PID=$!

# Wait for ipp-usb to initialize the HTTP bridge
echo "Waiting for ipp-usb HTTP bridge..."
for i in $(seq 1 15); do
    if curl -sf http://localhost:60000/eSCL/ScannerCapabilities >/dev/null 2>&1; then
        echo "  ✓ ipp-usb bridge ready on port 60000"
        break
    fi
    if ! kill -0 $IPP_USB_PID 2>/dev/null; then
        echo "  ⚠ ipp-usb exited unexpectedly"
        break
    fi
    sleep 1
done

# ── Diagnostics ───────────────────────────────────────
echo ""
echo "USB devices:"
lsusb 2>/dev/null | grep -iE "hp|scan|03f0" | sed 's/^/  /' || echo "  ⚠ No HP scanner found on USB"

echo ""
echo "SANE detection:"
scanimage -L 2>&1 | sed 's/^/  /' || echo "  ⚠ No SANE devices found"

echo ""
echo "Settings:"
echo "  Color:   $(cat /var/lib/scanner/color_mode 2>/dev/null || echo 'Color')"
echo "  Duplex:  $(cat /var/lib/scanner/duplex_mode 2>/dev/null || echo 'off')"
echo "  DPI:     ${SCAN_DPI:-300}"
echo "  Output:  /output"
echo ""
echo "Commands:"
echo "  docker exec scanner toggle-color     # switch Color/Gray"
echo "  docker exec scanner toggle-duplex    # switch Simplex/Duplex"
echo "  docker exec scanner scanner-status   # show scanner status"
echo ""
echo "────────────────────────────────────────────"
echo "Load paper into ADF to start scanning"
echo "────────────────────────────────────────────"

# ── Start ADF monitor ────────────────────────────────
exec /scripts/adf-monitor.sh
