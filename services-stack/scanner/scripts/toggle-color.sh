#!/bin/bash
# toggle-color.sh — Toggle between Color and Gray scanning mode
#
# Usage:
#   docker exec scanner toggle-color
#
# This affects the scan and copy/fax button actions which use
# the "current color mode". Email and PDF buttons always use
# their fixed color modes (Gray).

COLOR_MODE_FILE="/etc/scanbd/color_mode"
CURRENT=$(cat "$COLOR_MODE_FILE" 2>/dev/null || echo "Color")

if [ "$CURRENT" = "Color" ]; then
    echo "Gray" > "$COLOR_MODE_FILE"
    echo "Color mode: Gray → takes effect on next scan"
else
    echo "Color" > "$COLOR_MODE_FILE"
    echo "Color mode: Color → takes effect on next scan"
fi
