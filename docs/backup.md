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

**Current status:** ZeroByte is deployed to the `services-stack` but not yet configured with backup targets or schedules.

### Setup

> [!NOTE]
> The following steps will be documented once the backup pipeline is fully configured and tested.

1. Configure the Rclone remote for Google Drive access (credentials managed via Agenix).
2. Define the host directories to mount into the ZeroByte container as read-only backup sources.
3. Set up Restic repositories and encryption passphrases.
4. Configure backup schedules and retention policies.
5. Verify the initial backup completes successfully.

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

> [!NOTE]
> Detailed steps will be documented once the cloud backup pipeline is operational.

1. Install Restic and Rclone on a fresh machine.
2. Configure the Rclone remote with the Google Drive credentials.
3. Mount or restore the Restic repository.
4. Copy the restored data to the appropriate application volume paths.
5. Restart the affected containers.

### Recovering a VM from PBS

> [!NOTE]
> Detailed steps will be documented once PBS is deployed.

1. Access the Proxmox UI.
2. Select the target storage containing the PBS backups.
3. Restore the VM from the desired snapshot.
4. Verify network configuration and service health post-restore.

### Full Disaster Recovery

In the event of total hardware failure:

> [!NOTE]
> This procedure will be validated once both backup targets are operational.

1. **Rebuild the hypervisor:** Install Proxmox on replacement hardware.
2. **Restore VMs:** If PBS backups are available on surviving hardware, restore VMs directly. Otherwise, provision fresh NixOS VMs from the ISO.
3. **Reapply NixOS configs:** Clone this repository and run `colmena apply` to reconstruct all node configurations declaratively.
4. **Restore application data:** Pull data from Google Drive using the Restic/Rclone recovery procedure above.
5. **Verify:** Confirm all services are running and data integrity is intact.
