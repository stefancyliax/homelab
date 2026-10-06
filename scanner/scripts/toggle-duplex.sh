#!/bin/bash
# toggle-duplex.sh — Toggle between Simplex and Duplex scanning
#
# Usage:
#   docker exec scanner toggle-duplex

STATE_FILE="/var/lib/scanner/duplex_mode"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

if [ "$CURRENT" = "on" ]; then
    echo "off" > "$STATE_FILE"
    echo "Duplex mode: OFF (simplex) → takes effect on next scan"
else
    echo "on" > "$STATE_FILE"
    echo "Duplex mode: ON (duplex) → takes effect on next scan"
fi
