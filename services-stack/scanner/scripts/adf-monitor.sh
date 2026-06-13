#!/bin/bash
# adf-monitor.sh — ADF auto-scan daemon
#
# Polls the scanner's eSCL ScannerStatus endpoint.
# When paper is loaded into the ADF, waits ADF_LOAD_DELAY seconds
# (for the user to finish loading), then triggers a scan.
#
# Environment:
#   ADF_POLL_INTERVAL — seconds between status checks (default: 2)
#   ADF_LOAD_DELAY    — seconds to wait after ADF loaded (default: 5)

set -u

ESCL_URL="http://localhost:60000/eSCL/ScannerStatus"
POLL_INTERVAL="${ADF_POLL_INTERVAL:-2}"
LOAD_DELAY="${ADF_LOAD_DELAY:-5}"

get_adf_state() {
    curl -sf "$ESCL_URL" 2>/dev/null | grep -oP '<scan:AdfState>\K[^<]*' || echo "unknown"
}

echo "ADF monitor started (poll: ${POLL_INTERVAL}s, delay: ${LOAD_DELAY}s)"
echo ""

LAST_STATE=""

while true; do
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
