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

## Deployment (`storage-node` on `vault`)

The service is part of the `storage-stack` ([docker-compose.yml](../docker-compose.yml)) and is built from this directory on deployment.

- **USB**: the scanner is plugged into `vault` and passed through to the `storage-node` VM by vendor/product ID, so it does not matter which port it is on (see [proxmox-setup.md](../../docs/proxmox-setup.md#usb-passthrough)). The container gets the whole `/dev/bus/usb` tree, so it finds the scanner on whichever bus and address the VM assigns.
- **Output**: `storage-node` automounts the `paperless-consume` Samba share of `services-node` at `/mnt/paperless-consume` (`fileSystems` in `NixOS/nodes/storage-node/configuration.nix`), and the container binds it to `/output`. The bind uses `rslave` propagation: the share is only mounted on first access, and without it the mount would not reach an already running container.
- **Atomic delivery**: `scan.sh` and `scan-flatbed.sh` copy the PDF to the share as `.<name>.pdf.tmp` and rename it, so Paperless never consumes a half-written file. If the share is unreachable the scan is reported as failed instead of saved.

### Bring-up

- [ ] Pass the scanner through to the VM on `vault` (see [proxmox-setup.md](../../docs/proxmox-setup.md#usb-passthrough)) and check it shows up in the guest: `grep -H . /sys/bus/usb/devices/*/idVendor | grep 03f0`.
- [ ] After Comin has applied the NixOS change, check the share: `ls /mnt/paperless-consume`.
- [ ] After Dockhand has deployed the stack, check `docker logs scanner` and `docker exec scanner scanner-status`.
- [ ] Place a test sheet in the ADF and confirm the PDF arrives in Paperless.
