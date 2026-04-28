# Proxmox Setup

This document details the configuration of the Proxmox VE hypervisor and the baseline setup for its virtual machines.

For the full hardware specs and VM landscape, see [architecture.md](architecture.md).

## Storage Configuration

The Proxmox host contains three physical 512 GB SSDs. ZFS is not used — each disk is assigned an independent role to separate IO workloads:

| Drive | Role |
|---|---|
| Drive 1 | Proxmox OS, ISOs, and CT templates |
| Drive 2 | VM disks (NixOS instances, HAOS, etc.) |
| Drive 3 | Bulk data storage or backup staging |

> [!NOTE]
> Exact mount points and LVM configurations will be documented here once fully finalized.

## Virtual Networks

Proxmox uses a standard bridge network (`vmbr0`) by default.

- **IoT VLAN:** A separate VLAN tag is passed via the Unifi gear. VMs that need direct access to smart home devices (like the HAOS VM) are attached to this VLAN.
- **Tailscale Subnet Router:** A dedicated VM ensures the Proxmox host and its subnets are reachable from remote devices via Tailscale.

## VM Provisioning Baseline

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

All configuration is done in the Proxmox web UI under **Datacenter → Notifications**.

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

