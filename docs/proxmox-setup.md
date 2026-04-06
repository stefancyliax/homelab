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
