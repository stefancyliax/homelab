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

## Hardware Acceleration & PCIe Passthrough

To enable hardware transcoding (e.g., for Jellyfin or Frigate) inside a VM like the `services-node`, the host must physically pass the Intel iGPU to the VM.

> [!WARNING]
> Passing through the primary GPU will likely cause the Proxmox host's local physical display to freeze or go black after boot. This is normal and expected for a headless server managed via the web UI or SSH.

### 1. Enable IOMMU
You must enable IOMMU in the host's bootloader. Proxmox uses either GRUB or systemd-boot depending on the install method.

**For GRUB (Legacy/Default):**
Edit `/etc/default/grub` and update the `GRUB_CMDLINE_LINUX_DEFAULT` line:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```
Apply the changes: `update-grub`

**For systemd-boot (ZFS or UEFI installs):**
Edit `/etc/kernel/cmdline` and append `intel_iommu=on iommu=pt`.
Apply the changes: `proxmox-boot-tool refresh`

### 2. Load VFIO Modules
These kernel modules allow the host to detach the GPU. Edit `/etc/modules` and add the following lines:
```text
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

Reboot the Proxmox host for the changes to take effect.

### 3. Assign the PCI Device to the VM
1. In the Proxmox Web UI, navigate to the `services-node` VM.
2. Go to **Hardware** -> **Add** -> **PCI Device**.
3. Select the Intel iGPU (typically something like `0000:00:02.0 VGA compatible controller`).
4. Keep **All Functions** checked. If passthrough works incorrectly, you may also need to check **Primary GPU**, though keeping it off is usually safest for iGPUs initially.
5. Boot the VM. The guest OS will now be able to initialize the GPU and provide `/dev/dri` to the Docker stack.
