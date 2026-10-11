#!/bin/bash
# scanner-status.sh — Show current scanner status and settings
#
# Usage:
#   docker exec scanner scanner-status

echo "=== USB Devices ==="
lsusb 2>/dev/null | grep -iE "hp|scan|03f0" || echo "  (no HP/scanner USB devices found)"

echo ""
echo "=== SANE Devices ==="
scanimage -L 2>&1

echo ""
echo "=== eSCL Scanner Status ==="
STATUS=$(curl -sf http://localhost:60000/eSCL/ScannerStatus 2>/dev/null)
if [ -n "$STATUS" ]; then
    STATE=$(echo "$STATUS" | grep -oP '<pwg:State>\K[^<]*' || echo "unknown")
    ADF=$(echo "$STATUS" | grep -oP '<scan:AdfState>\K[^<]*' || echo "unknown")
    echo "  State:     $STATE"
    echo "  ADF:       $ADF"
else
    echo "  ⚠ ipp-usb bridge not responding"
fi

echo ""
echo "=== Current Settings ==="
echo "  Color:   $(cat /var/lib/scanner/color_mode 2>/dev/null || echo 'Color')"
echo "  Duplex:  $(cat /var/lib/scanner/duplex_mode 2>/dev/null || echo 'off')"
echo "  DPI:     ${SCAN_DPI:-300}"
echo ""
echo "=== Commands ==="
echo "  toggle-color     Switch Color/Gray"
echo "  toggle-duplex    Switch Simplex/Duplex"
echo "  scanner-status   This output"
