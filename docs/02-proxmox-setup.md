# 02 - Proxmox Setup

This section details the expected configuration of the core Proxmox VE hypervisor and the setup steps for its virtual machines to guide actual implementation.

## 💾 Storage Configuration

The Proxmox host contains three physical 512GB SSDs. Due to differences in application IO and separation of concerns, **ZFS is not used**. 

The disks are planned to be partitioned with specific independent roles (e.g.):
1. **Drive 1:** Proxmox OS & ISOs / CT Templates.
2. **Drive 2:** VM Disks (NixOS instances, HAOS, etc.).
3. **Drive 3:** Bulk data storage or backup staging.

> [!NOTE]
> *Exact mount points and LVM configurations need to be documented here once fully implemented and finalized.*

## 🔌 Virtual Networks

By default, Proxmox uses a standard bridge network (`vmbr0`).
* **IoT VLAN:** A separate VLAN tag is passed via the Unifi gear. VMs that need direct access to smart home devices (like the HAOS VM) should be attached to this VLAN.
* **Tailscale Subnet Router:** Deployed via VM to ensure the Proxmox host and its subnets are cleanly reachable from remote devices via Tailscale.

## 📦 VM Provisioning Checklist

When deploying new VMs (like the NixOS nodes), follow this baseline configuration:

- **CPU type:** Set to `host` for maximum performance and modern instruction sets. *(Note: Using `host` passes the physical host CPU model hardware features directly to the VM rather than the generic `kvm64` model. This improves performance but assumes nodes won't be live-migrated to totally different CPU architectures).*
- **QEMU Guest Agent:** Enable it specifically in the Proxmox UI for the VM and ensure the service is running in the guest OS (e.g., configured in `common.nix` for NixOS nodes).
- **Firmware:** Currently **SeaBIOS** is used for the existing NixOS VMs. *(See Master To-Do list: Research migrating to UEFI / OVMF).*

### HAOS VM (Currently Running)
The Home Assistant Operating System (HAOS) is already actively running as a dedicated Virtual Machine attached to the IoT VLAN.
