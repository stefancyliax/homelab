# Backup

This document describes the backup strategy for the homelab — how data is backed up, where it goes, and how to recover from failures.

## What Gets Backed Up

| Data | Backup Method | Notes |
|---|---|---|
| This repository | GitHub | The Git repo is the source of truth for all NixOS configs, Docker Compose files, and documentation. Inherently backed up by being hosted on GitHub. |
| Application volumes | ZeroByte → Google Drive | Databases and bind mounts: Paperless data, NocoDB tables, Home Assistant state, Nextcloud/Seafile files. |
| Proxmox host config | Manual / PBS | Network interfaces, storage definitions, `/etc/pve` backups. |
| Full VM images | PBS (planned) | Block-level incremental backups for rapid local restoration. |

## Cloud Backups (ZeroByte)

### Overview

The primary backup strategy relies on [ZeroByte](https://github.com/nicotsx/zerobyte) to push encrypted, deduplicated backups to Google Drive via Restic. This ensures critical data survives total physical site loss.

**Current status:** ✅ ZeroByte is deployed and functional in the `services-stack` with configured backup targets, schedules, and retention policies.

### Setup & Pipeline Architecture

The backup pipeline is fully integrated into the GitOps and NixOS configuration:

1. **Rclone Configuration:** Google Drive remote credentials are encrypted via Agenix (`secrets/rclone-conf.age`) and automatically decrypted to `/etc/rclone/rclone.conf` on the `services-node`.
2. **Read-only Volume Mounts:** The host application storage (`/mnt/data`) is mounted into the ZeroByte container as a read-only volume (`/mnt/data:/mnt/data:ro`), preventing accidental modifications during backups.
3. **Automated Database & Media Exports:** Rather than relying solely on live database volume snapshots, `services-node` runs an automated daily systemd timer (`paperless-exporter`) at 02:00:
   ```bash
   docker exec paperless-ngx document_exporter /usr/src/paperless/export --delete
   ```
   This exports consistent database dumps and media archives into `/mnt/data/paperless/export` right before ZeroByte triggers its offsite sync.
4. **Notifications:** ZeroByte is configured with `WEBHOOK_ALLOWED_ORIGINS=http://10.1.23.184:2586` to publish backup success/failure reports directly to the `homelab-backups` topic on ntfy.

## Local Backups (Planned)

### Overview

A local backup target provides rapid restoration when a single VM fails, gets corrupted, or is accidentally misconfigured.

- **Hardware:** Intel NUC i3 (to be replaced by a dedicated NAS).
- **Method:** Proxmox Backup Server (PBS) for deduplicated, block-level incremental VM backups.

### Setup

> [!NOTE]
> The following steps will be documented once PBS is deployed and configured.

1. Install PBS on the Intel NUC (or the future NAS).
2. Configure the Proxmox host to use the PBS instance as a backup target.
3. Set up scheduled VM backup jobs.
4. Define retention policies.
5. Test a full VM restore.

## Recovery Procedures

### Recovering Application Data from Google Drive

1. Install Restic and Rclone on the recovery node.
2. Configure the Rclone remote using the credentials from `secrets/rclone-conf.age`.
3. Mount or restore the target repository:
   ```bash
   restic -r rclone:gdrive:/homelab-backups restore latest --target /mnt/data
   ```
4. Restart the affected containers via Dockhand.

### Recovering a VM from PBS

> [!NOTE]
> Detailed steps will be documented once PBS is deployed.

1. Access the Proxmox UI.
2. Select the target storage containing the PBS backups.
3. Restore the VM from the desired snapshot.
4. Verify network configuration and service health post-restore.

### Full Disaster Recovery

In the event of total hardware failure:

1. **Rebuild the hypervisor:** Install Proxmox on replacement hardware.
2. **Restore VMs:** If PBS backups are available on surviving hardware, restore VMs directly. Otherwise, provision fresh baseline NixOS VMs.
3. **Reapply NixOS configs:** Clone this repository, bootstrap each node with `nixos-rebuild switch --flake .#<node-name>`, and allow Comin to take over declarative management.
4. **Restore application data:** Pull data from Google Drive using the Rclone/ZeroByte recovery procedure above.
5. **Verify:** Confirm all services are running and data integrity is intact.
