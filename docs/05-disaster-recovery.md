# 05 - Disaster Recovery & Backups

This document outlines the backup policies to ensure that all virtual machines, application data, and configurations can be restored in the event of hardware failure.

## 🛡️ Backup Strategy

### Primary Approach: Extramural Encrypted Cloud Backups
The core strategy relies on pushing encrypted backups securely to Google Drive. This ensures highly critical data (like Paperless documents, photos, and essential database dumps) survive total physical site loss or critical array failures.

### Secondary Approach: Local Target (Planned)
* **Hardware:** An Intel NUC i3 (to be replaced eventually by a proper NAS using ZimaOS/Unraid) will serve as a local backup target.
* **Method:** Considering running a Proxmox Backup Server (PBS) instance to handle deduplicated, block-level incremental backups of the full VMs.
* **Goal:** Provides rapid local restoration capabilities if a single VM fails, gets corrupted, or is accidentally misconfigured.

## 📂 What Needs to be Backed Up?

1. **The Repository (GitHub):** This Git repository acts as the fundamental source of truth for the entire architecture (NixOS files, docker-compose files). The configuration state is backed up inherently by syncing with GitHub.
2. **Application Volumes (Persistent Data):** Specifically, databases and bind mounts containing Paperless data, NocoDB tables, Home Assistant states, and Nextcloud/Seafile files.
3. **Proxmox Host Config:** Network interfaces, storage definitions, and basic `/etc/pve` backups.

## ♻️ Restoration Procedures

> [!WARNING]
> **TODO:** Exact steps for disaster recovery from Google Drive or the local repository need to be heavily researched and exhaustively listed here once the backup flow is technically implemented.
