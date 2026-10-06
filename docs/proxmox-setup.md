# Proxmox Setup

This document details the configuration of the Proxmox VE hypervisor and the baseline setup for its virtual machines.

For the full hardware specs and VM landscape, see [architecture.md](architecture.md).

## Multi-Host Management

The two Proxmox hosts, `phil` and `vault`, are standalone; there is no cluster:

- A two-node cluster loses quorum when either node is down and needs a QDevice to work around it.
- [Proxmox Datacenter Manager](https://pdm.proxmox.com/docs/) (PDM) provides the combined view and cross-host migration without a cluster.

PDM runs as a VM on `phil` with both hosts added as remotes, reachable at `https://proxmox.home.stefancyliax.de`. It is not GitOps-managed.

## Storage Configuration

### `phil`

The host has two SSDs, each with an independent role and no redundancy. Proxmox storages (`/etc/pve/storage.cfg`):

| Storage | Type | Backing | Content |
|---|---|---|---|
| `local` | Directory (`/var/lib/vz`) | Boot disk, root filesystem | ISOs, CT templates, import images |
| `local-lvm` | LVM-thin (`pve/data`) | Boot disk, remaining space | VM disks, CT root disks |
| `ZFS-Store` | ZFS pool, single disk | Samsung 860 EVO M.2 500 GB (SATA) | VM disks, CT root disks — holds the data disk of `services-node` |

- `ZFS-Store` has no redundancy: ZFS detects corruption there but cannot repair it.
- No storage has `backup` content enabled, in line with the decision against VM image backups.
- BTRFS is not used for Proxmox storage: its integration is still a technology preview, while LVM-thin and ZFS are fully supported.

`services-node` gets its application data disk (Paperless etc.) as a virtual disk on `ZFS-Store`, formatted ext4 inside the VM and mounted at `/mnt/data`. The SSD itself is not passed through.

🔲 Planned layout: no ZFS, data disks passed through whole.

| Disk | Target |
|---|---|
| Boot disk | `local` + `local-lvm` (all VM and CT OS disks) |
| Samsung 860 EVO M.2 500 GB | `services-node`, ext4 at `/mnt/data` |
| Samsung 250 GB SSD (not yet installed) | `frigate-node`, recordings |

The conversion of the 860 EVO from ZFS to ext4 is tracked as a task in the [README](../README.md).

### `vault`

| Drive | Role |
|---|---|
| NVMe SSD | Proxmox OS, `local` (100 GB) and `local-lvm` (~400 GB, all guest disks) |
| SATA SSD | Unassigned |
| 6 TB HDD | 🔲 Planned: passed through by-id to `nas-node` (bulk/media), btrfs |
| 1 TB HDD | 🔲 Planned: passed through by-id to `nas-node` (Garage, scratch), XFS |
| 2 TB HDD | 🔲 Planned: passed through by-id to `nas-node` (local backup copy of important shares), btrfs |

Proxmox is installed with ext4/LVM; the 100 GB root (and with it `local`) is set through the installer's `maxroot` option, and `local-lvm` takes the rest.

The HDDs are passed through individually (`/dev/disk/by-id/...`), not via the SATA controller, which keeps the SATA SSD on that controller available to the host.

## iGPU Passthrough (Planned)

| Host | iGPU | Target VM | Consumer |
|---|---|---|---|
| `phil` | Iris Xe (80 EU) | `frigate-node` | Frigate (decode + OpenVINO detection) |
| `vault` | UHD 770 (32 EU) | `nas-node` | Jellyfin (QuickSync transcoding) |

Full passthrough gives the iGPU to one VM and the host loses its local console. It is not yet validated on either host and is the first thing to test. Fallback: run the consumer in a CT with `/dev/dri` shared from the host.

> [!NOTE]
> Exact mount points and LVM configurations will be documented here once fully finalized.

## Virtual Networks

Proxmox uses a standard bridge network (`vmbr0`) by default.

- **IoT VLAN:** A separate VLAN tag is passed via the Unifi gear. VMs that need direct access to smart home devices (like the HAOS VM) are attached to this VLAN.
- **Tailscale Subnet Router:** A dedicated VM ensures the Proxmox host and its subnets are reachable from remote devices via Tailscale.

## VM Provisioning Baseline

For when to use a VM, a CT or Docker, see [Workload Placement](architecture.md#workload-placement).

When deploying new VMs, apply the following baseline configuration:

| Setting | Value | Notes |
|---|---|---|
| CPU Type | `host` | Passes physical CPU features directly to the VM. Improves performance but prevents live-migration to different CPU architectures. |
| QEMU Guest Agent | Enabled | Must be enabled both in the Proxmox UI and inside the guest OS (configured in `common.nix` for NixOS nodes). |
| Firmware | SeaBIOS | Used for existing VMs. Migrating to UEFI/OVMF is not worth the effort (requires repartitioning). All new VMs should use OVMF. |

## HAOS VM

The Home Assistant Operating System is actively running as a dedicated VM attached to the IoT VLAN. See [home-assistant.md](home-assistant.md) for details.

## Notifications (ntfy)

Proxmox VE has a built-in notification system with native webhook support. This allows routing all Proxmox events (backup results, storage replication failures, node fencing, package updates) directly to the self-hosted ntfy instance.

### Setup

All configuration is done in the Proxmox web UI under **Datacenter → Notifications**. Both hosts, `phil` and `vault`, are set up this way.

#### 1. Create the Webhook Target

Navigate to **Targets → Add → Webhook** and configure:

| Field | Value |
|---|---|
| **Name** | `ntfy` |
| **Method** | `POST` |
| **URL** | `http://10.1.23.184:2586/homelab-system` |
| **Body** | `{{ message }}` |
| **Comment** | `Push notifications via self-hosted ntfy` |

**Headers:**

| Header | Value |
|---|---|
| `Title` | `{{ title }}` |
| `Tags` | `computer` |
| `Markdown` | `yes` |

> [!WARNING]
> Do **not** set a `Priority` header using `{{ severity }}`. Proxmox outputs values like `info`, `warning`, `error`, but ntfy only accepts `min`, `low`, `default`, `high`, `max` (or `1`–`5`). Sending an invalid priority causes a `400 Bad Request`. The severity is already included in the message body by Proxmox.

> [!NOTE]
> Proxmox uses [Handlebars](https://handlebarsjs.com/) templating in webhook fields. No authentication is needed — the ntfy instance is configured with open access (`read-write`) on the LAN.

#### 2. Create a Matcher

Navigate to **Matchers → Add** and configure:

| Field | Value |
|---|---|
| **Name** | `ntfy-all` |
| **Target** | `ntfy` |
| **Comment** | `Route all Proxmox events to ntfy` |

Leave matching rules empty to match **all** notification events. Alternatively, create separate matchers for different severity levels:

```
# Example: Only send warnings and errors
matcher: ntfy-critical
  match-severity warning,error
  target ntfy
  comment Only critical events
```

#### 3. Test

Use the **Test** button in the target configuration to verify connectivity. You should receive a test notification on your subscribed ntfy client.

### Proxmox Notification Events

These are the events that Proxmox will forward to ntfy:

| Event | Type | Severity |
|---|---|---|
| Backup succeeded | `vzdump` | `info` |
| Backup failed | `vzdump` | `error` |
| Storage replication failed | `replication` | `error` |
| Cluster node fenced | `fencing` | `error` |
| System updates available | `package-updates` | `info` |
| System mail (smartd, etc.) | `system-mail` | `unknown` |

