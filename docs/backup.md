# Backup

This document describes the backup strategy for the homelab — how data is backed up, where it goes, and how to recover from failures.

## What Gets Backed Up

| Data | Backup Method | Notes |
|---|---|---|
| This repository | GitHub | The Git repo is the source of truth for all NixOS configs, Docker Compose files, and documentation. Inherently backed up by being hosted on GitHub. |
| Application volumes | ZeroByte → Google Drive | Databases and bind mounts: Paperless data, NocoDB tables, Home Assistant state, Nextcloud/Seafile files. |
| Proxmox host config | Manual | Network interfaces, storage definitions, `/etc/pve` backups. |
| Full VM images | Not backed up | NixOS VMs are rebuilt from this repository; only their data is backed up. See [Local Backups](#local-backups). |
| NAS shares | Local copy + cloud (planned) | See [NAS Data](#nas-data--planned). |

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

## Local Backups

### VM Images

Full VM images are not backed up, and there is no Proxmox Backup Server:

- NixOS VMs hold no unique state outside their data directories and are rebuilt from this repository.
- Application data is covered by ZeroByte.
- Guests outside GitOps (HAOS, Proxmox Datacenter Manager) rely on their own backup/export features or are quick to set up again.

### NAS Data (🔲 Planned)

The HDDs in `storage-node` run without parity, so protection comes from copies:

| Data | Protection |
|---|---|
| Important shares | Local copy on the 2 TB disk (restic) + offsite to Google Drive (ZeroByte/restic) |
| Home Assistant backups | HAOS writes its built-in backups to a NAS share, which is treated as an important share |
| Media | None — re-acquirable |
| Garage (dev data) | None |

## Recovery Procedures

### Recovering Application Data from Google Drive

1. Install Restic and Rclone on the recovery node.
2. Configure the Rclone remote using the credentials from `secrets/rclone-conf.age`.
3. Mount or restore the target repository:
   ```bash
   restic -r rclone:gdrive:/homelab-backups restore latest --target /mnt/data
   ```
4. Restart the affected containers via Dockhand.

### Recovering a VM

There are no VM image backups. To recover a NixOS VM:

1. Clone the NixOS template in Proxmox (see [deployment.md](deployment.md#vm-templating--cloning)).
2. Bootstrap it with `nixos-rebuild switch --flake .#<node-name>`; Comin takes over afterwards.
3. If the VM uses secrets, add its new host key to `secrets.nix` and re-key Agenix.
4. Restore the application data from Google Drive as described above.

### Full Disaster Recovery

In the event of total hardware failure:

1. **Rebuild the hypervisor:** Install Proxmox on replacement hardware.
2. **Recreate VMs:** Provision fresh baseline NixOS VMs.
3. **Reapply NixOS configs:** Clone this repository, bootstrap each node with `nixos-rebuild switch --flake .#<node-name>`, and allow Comin to take over declarative management.
4. **Restore application data:** Pull data from Google Drive using the Rclone/ZeroByte recovery procedure above.
5. **Verify:** Confirm all services are running and data integrity is intact.
