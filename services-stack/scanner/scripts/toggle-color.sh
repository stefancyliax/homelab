#!/bin/bash
# toggle-color.sh — Toggle between Color and Gray scanning mode
#
# Usage:
#   docker exec scanner toggle-color

STATE_FILE="/var/lib/scanner/color_mode"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "Color")

if [ "$CURRENT" = "Color" ]; then
    echo "Gray" > "$STATE_FILE"
    echo "Color mode: Gray → takes effect on next scan"
else
    echo "Color" > "$STATE_FILE"
    echo "Color mode: Color → takes effect on next scan"
fi
