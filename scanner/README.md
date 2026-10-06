# Scanner Service (HP ScanJet Pro 2600 f1)

This service manages the physical document scanner for the homelab. It runs as a Docker container, interfacing with an **HP ScanJet Pro 2600 f1** flatbed/ADF scanner over USB, monitoring the Automatic Document Feeder (ADF), and delivering scanned PDFs directly into Paperless-ngx.

---

## How It Works

1. **IPP-over-USB Bridge (`ipp-usb`)**:
   - The scanner communicates via the eSCL (Apple AirScan) protocol encapsulated in USB.
   - `ipp-usb` runs in standalone mode inside the container, exposing an HTTP endpoint on `http://localhost:60000/eSCL`.
2. **SANE Airscan (`sane-airscan`)**:
   - SANE connects to `http://localhost:60000/eSCL` statically configured in `/etc/sane.d/airscan.conf` (no Avahi/mDNS daemon required).
3. **ADF Auto-Detection (`scripts/adf-monitor.sh`)**:
   - The daemon continuously polls the eSCL status endpoint (`/eSCL/ScannerStatus`).
   - When paper is loaded into the ADF (`<scan:AdfState>ScannerAdfLoaded`), it waits `ADF_LOAD_DELAY` seconds, then triggers `scripts/scan.sh`.
4. **Scan & PDF Generation (`scripts/scan.sh`)**:
   - Scans all pages from the feeder in batch mode via `scanimage`.
   - Converts the resulting TIFF pages into a multi-page PDF using `img2pdf --pillow-limit-break`.
   - Saves the final PDF into `/output` (bound to Paperless-ngx consume directory).
5. **Reconnection & Self-Healing**:
   - If the scanner enters sleep mode or power-cycles, `adf-monitor.sh` detects the USB disconnection and automatically restarts `ipp-usb` once the USB device reappears.

---

## Manual Commands

You can interact with the running container at any time:

```bash
docker exec scanner scanner-status   # Show USB detection, SANE status, and current modes
docker exec scanner toggle-color     # Toggle between Color and Gray
docker exec scanner toggle-duplex    # Toggle between Simplex (ADF) and Duplex (ADF Duplex)
docker exec scanner scan-flatbed     # Trigger a single-page scan from the flatbed glass
```

---

## Open Points / Checklist (When the New Proxmox Node is Online)

When the secondary Proxmox physical node is provisioned and online, complete the following setup steps:

- [ ] **1. Physical USB Connection & Passthrough**:
  - Connect the HP ScanJet Pro 2600 f1 to a USB port on the new Proxmox host.
  - If running in an LXC container or VM on Proxmox, pass through the USB device (Vendor ID `03f0`).
- [ ] **2. Dynamic USB Bus Mapping in `docker-compose.yaml`**:
  - In `scanner/docker-compose.yaml`, change `/dev/bus/usb/002:/dev/bus/usb/002` to:
    ```yaml
    volumes:
      - /dev/bus/usb:/dev/bus/usb
    ```
    This ensures `lsusb` and `ipp-usb` detect the scanner regardless of which USB bus or port it is assigned to on the new host.
- [ ] **3. Ingestion Network Mount (`/output`)**:
  - Since this container runs on a different node than `services-node` (`10.1.23.224`), mount the Samba share on the host:
    ```bash
    //10.1.23.224/paperless-consume -> /mnt/paperless-consume
    ```
  - Update `docker-compose.yaml` to bind-mount the network share:
    ```yaml
    volumes:
      - /mnt/paperless-consume:/output
    ```
- [ ] **4. Atomic Copy to Prevent Race Conditions**:
  - When copying across a network share, Paperless might try to consume an incomplete PDF while `cp` is still writing.
  - In `scanner/scripts/scan.sh` and `scanner/scripts/scan-flatbed.sh`, use an atomic copy:
    ```bash
    cp "${TEMP_DIR}/${FILENAME}.pdf" "${OUTPUT_DIR}/.${FILENAME}.pdf.tmp"
    mv "${OUTPUT_DIR}/.${FILENAME}.pdf.tmp" "${OUTPUT_DIR}/${FILENAME}.pdf"
    ```
- [ ] **5. Deploy & Verify**:
  - Start the stack: `docker compose up -d --build`.
  - Check startup logs: `docker compose logs -f`.
  - Place a test sheet in the ADF to verify automatic scan and Paperless ingestion.
