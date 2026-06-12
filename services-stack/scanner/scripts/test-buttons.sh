#!/bin/bash
# test-buttons.sh — Discover scanner buttons and SANE options
#
# Usage:
#   docker exec scanner test-buttons
#
# This script helps identify which SANE option names correspond
# to physical scanner buttons, so you can adjust scanbd.conf.

echo "=== USB Devices ==="
lsusb 2>/dev/null | grep -iE "hp|scan|03f0" || echo "  (no HP/scanner USB devices found)"

echo ""
echo "=== SANE Devices ==="
scanimage -L 2>&1

echo ""
DEVICE=$(scanimage -L 2>/dev/null | head -1 | sed "s/.*\`//" | sed "s/'.*//" || echo "")

if [ -z "$DEVICE" ]; then
    echo "⚠ No SANE device found."
    echo "  Check that the USB device is passed through to the container."
    echo "  Verify with: lsusb"
    exit 1
fi

echo "=== Scanner Options ==="
echo "  Device: $DEVICE"
echo ""
echo "  Look for button-related options (scan, copy, email, pdf, fax)."
echo "  These are the options you can map in scanbd.conf."
echo ""
scanimage --device-name="$DEVICE" -A 2>&1

echo ""
echo "=== Button Detection Test ==="
echo "  To test live button detection, run:"
echo ""
echo "    docker exec scanner scanbd -d7 -f -c /etc/scanbd/scanbd.conf"
echo ""
echo "  Then press buttons on the scanner and watch for events."
echo "  Ctrl+C to stop."
echo ""
echo "=== Current Color Mode ==="
echo "  $(cat /etc/scanbd/color_mode 2>/dev/null || echo 'Color')"
echo "  Toggle with: docker exec scanner toggle-color"
