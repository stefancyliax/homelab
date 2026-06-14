#!/bin/bash
# adf-monitor.sh — ADF auto-scan daemon with ipp-usb reconnection
#
# Polls the scanner's eSCL ScannerStatus endpoint.
# When paper is loaded into the ADF, waits ADF_LOAD_DELAY seconds
# (for the user to finish loading), then triggers a scan.
#
# If the scanner disconnects (power-save, USB reset), the monitor
# automatically restarts ipp-usb when the scanner comes back online.
#
# Environment:
#   ADF_POLL_INTERVAL — seconds between status checks (default: 2)
#   ADF_LOAD_DELAY    — seconds to wait after ADF loaded (default: 5)

set -u

ESCL_URL="http://localhost:60000/eSCL/ScannerStatus"
POLL_INTERVAL="${ADF_POLL_INTERVAL:-2}"
LOAD_DELAY="${ADF_LOAD_DELAY:-5}"
RECONNECT_INTERVAL=10
USB_VENDOR="03f0"

get_adf_state() {
    curl -sf "$ESCL_URL" 2>/dev/null | grep -oP '<scan:AdfState>\K[^<]*' || echo "unknown"
}

is_bridge_up() {
    curl -sf "$ESCL_URL" >/dev/null 2>&1
}

is_scanner_on_usb() {
    lsusb 2>/dev/null | grep -qi "$USB_VENDOR"
}

restart_ipp_usb() {
    echo "$(date '+%H:%M:%S') Restarting ipp-usb..."
    # Kill any existing ipp-usb processes forcefully
    pkill -9 -x ipp-usb 2>/dev/null || true
    sleep 1

    # Clear any stale locks or sockets that cause "already running" errors
    rm -rf /var/run/ipp-usb/* 2>/dev/null || true

    # Start fresh ipp-usb
    mkdir -p /var/run/ipp-usb
    ipp-usb standalone &

    # Wait for bridge to come up
    for i in $(seq 1 15); do
        if is_bridge_up; then
            echo "$(date '+%H:%M:%S') ✓ ipp-usb bridge reconnected"
            return 0
        fi
        sleep 1
    done

    echo "$(date '+%H:%M:%S') ⚠ ipp-usb bridge failed to start"
    return 1
}

echo "ADF monitor started (poll: ${POLL_INTERVAL}s, delay: ${LOAD_DELAY}s)"
echo ""

LAST_STATE=""
CONNECTED=true

while true; do
    # ── Connection check ──────────────────────────────
    if ! is_bridge_up; then
        if [ "$CONNECTED" = true ]; then
            echo "$(date '+%H:%M:%S') 🔌 Scanner disconnected"
            CONNECTED=false
        fi

        # Wait for scanner to reappear on USB
        if is_scanner_on_usb; then
            echo "$(date '+%H:%M:%S') Scanner detected on USB — reconnecting..."
            if restart_ipp_usb; then
                CONNECTED=true
                LAST_STATE=""
            fi
        fi

        sleep "$RECONNECT_INTERVAL"
        continue
    fi

    # Mark as connected (handles first-run case)
    if [ "$CONNECTED" = false ]; then
        echo "$(date '+%H:%M:%S') ✓ Scanner online"
        CONNECTED=true
    fi

    # ── ADF monitoring ────────────────────────────────
    ADF_STATE=$(get_adf_state)

    # Only trigger on transition to ScannerAdfLoaded
    if [ "$ADF_STATE" = "ScannerAdfLoaded" ] && [ "$LAST_STATE" != "ScannerAdfLoaded" ]; then
        echo "$(date '+%H:%M:%S') 📄 Paper detected in ADF — waiting ${LOAD_DELAY}s..."
        sleep "$LOAD_DELAY"

        # Verify paper is still there (user might have removed it)
        ADF_STATE=$(get_adf_state)
        if [ "$ADF_STATE" = "ScannerAdfLoaded" ]; then
            echo "$(date '+%H:%M:%S') 🔄 Starting scan..."
            /scripts/scan.sh && {
                echo "$(date '+%H:%M:%S') ✓ Scan complete"
            } || {
                echo "$(date '+%H:%M:%S') ⚠ Scan failed"
            }

            # Wait for ADF to empty before resuming monitoring
            echo "$(date '+%H:%M:%S') Waiting for ADF to clear..."
            while [ "$(get_adf_state)" = "ScannerAdfLoaded" ]; do
                sleep "$POLL_INTERVAL"
            done
            echo "$(date '+%H:%M:%S') ADF empty — ready for next scan"
            echo ""
        else
            echo "$(date '+%H:%M:%S') Paper removed during wait — skipping"
        fi
    fi

    LAST_STATE="$ADF_STATE"
    sleep "$POLL_INTERVAL"
done
