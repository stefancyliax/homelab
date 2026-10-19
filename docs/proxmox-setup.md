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

The host has three SSDs, each with an independent role and no redundancy. Proxmox storages (`/etc/pve/storage.cfg`) live on the boot disk only:

| Storage | Type | Backing | Content |
|---|---|---|---|
| `local` | Directory (`/var/lib/vz`) | Boot disk, root filesystem | ISOs, CT templates, import images |
| `local-lvm` | LVM-thin (`pve/data`) | Boot disk, remaining space | VM disks, CT root disks |

- No ZFS on this host: the former `ZFS-Store` pool was destroyed on 2026-10-11, which also frees the memory ZFS used for caching.
- No storage has `backup` content enabled, in line with the decision against VM image backups.
- BTRFS is not used for Proxmox storage: its integration is still a technology preview, while LVM-thin and ZFS are fully supported.

Data disks are passed through whole, by-id, to the VM that uses them:

| Disk | Target |
|---|---|
| Boot disk | `local` + `local-lvm` (all VM and CT OS disks) |
| Samsung 860 EVO M.2 500 GB | `services-node` (`scsi1`), one ext4 partition at `/mnt/data` |
| SanDisk Ultra 3D 512 GB | 🔲 `frigate-node`, recordings. Until then attached to `services-node` (`scsi2`) with the rollback copy of `/mnt/data` from the migration |

`/mnt/data` is mounted by filesystem UUID (`fileSystems."/mnt/data"` in `nodes/services-node/configuration.nix`). When the 860 EVO replaced the old virtual disk, the new filesystem was created with the same UUID (`mkfs.ext4 -U`), so the NixOS config did not change.

Passed-through disks cannot be snapshotted by Proxmox; a VM with one attached only snapshots if that disk is excluded.

### `vault`

| Drive | Role |
|---|---|
| NVMe SSD | Proxmox OS, `local` (100 GB) and `local-lvm` (~400 GB, all guest disks) |
| SATA SSD | Passed through by-id to `agent-tools-node` (Garage data), XFS |
| 6 TB HDD | Passed through by-id to `storage-node` (bulk/media), btrfs labelled `data`, mounted at `/mnt/data` |
| 1 TB HDD | 🔲 Planned: passed through by-id to `storage-node` (scratch), XFS |
| 2 TB HDD | Passed through by-id to `storage-node` (local backup copy of important shares, for now also the media library), btrfs labelled `backup`, mounted at `/mnt/backup` |

Proxmox is installed with ext4/LVM; the 100 GB root (and with it `local`) is set through the installer's `maxroot` option, and `local-lvm` takes the rest.

The disks are passed through individually (`/dev/disk/by-id/...`), not via the SATA controller, so they can go to different VMs: the HDDs to `storage-node`, the SATA SSD to `agent-tools-node`.

Passing a disk through is done by hand on the host; the guest then mounts it by filesystem label, so its NixOS config does not depend on the disk's ID. For the Garage SSD:

```bash
ls -l /dev/disk/by-id/ | grep -v part                                              # on vault: find the disk
qm set <vmid> --scsi1 /dev/disk/by-id/ata-<model>_<serial>,discard=on,ssd=1,backup=0
nix shell nixpkgs#xfsprogs -c sudo mkfs.xfs -L garage-data /dev/sdX                # in the guest, once; wipes the disk
```

The HDDs go the same way, without `discard`/`ssd`. Passing the drive's serial makes it recognisable in the guest: `lsblk -o NAME,SIZE,SERIAL` shows it, while `/dev/disk/by-id/` names the disk after its slot (`scsi-0QEMU_QEMU_HARDDISK_drive-scsi1`). For the 2 TB backup disk:

```bash
qm set <vmid> --scsi1 /dev/disk/by-id/ata-<model>_<serial>,backup=0,iothread=1,serial=<serial>
sudo wipefs -a /dev/sdX                                                            # in the guest, once; wipes the disk
sudo nix shell nixpkgs#btrfs-progs -c mkfs.btrfs -L backup /dev/sdX
```

#### HDD Spin-Down

The guest only sees an emulated QEMU disk, so spin-down commands from inside the VM never reach the drive. Spin-down is set on `vault` itself, per disk in `/etc/hdparm.conf` (applied at boot by the `hdparm` package). `spindown_time = 240` means 20 minutes idle:

```
/dev/disk/by-id/ata-<model>_<serial> {
    spindown_time = 240
}
```

| Disk | Spin-down |
|---|---|
| 6 TB (bulk) | 20 minutes |
| 2 TB (backup) | 20 minutes |
| 1 TB (scratch) | 20 minutes |

`hdparm -C /dev/sdX` shows whether a drive is active or in standby; `hdparm -S 240 /dev/sdX` applies the setting immediately without a reboot. `smartd` on `vault` must run with `-n standby` in `/etc/smartd.conf`, otherwise its periodic checks wake the disks.

## iGPU Passthrough

| Host | iGPU | Target VM | Consumer | Status |
|---|---|---|---|---|
| `phil` | Iris Xe (80 EU) | `frigate-node` | Frigate (decode + OpenVINO detection) | 🔲 Planned |
| `vault` | UHD 770 (32 EU) | `storage-node` | Jellyfin (QuickSync transcoding) | ✅ Passed through (VM 891), VAAPI validated with `vainfo` |

Full passthrough gives the iGPU to one VM and the host loses its local console. It works on `vault` and is not yet validated on `phil`. Fallback: run the consumer in a CT with `/dev/dri` shared from the host.

The host side is set up by hand, not GitOps-managed. The steps below are for `vault`; `phil` works the same with its own device ID.

### Host

1. BIOS: enable VT-d (Advanced → System Agent (SA) Configuration).
2. Kernel command line in `/etc/default/grub`, then `update-grub`. `vault` boots with GRUB (ext4/LVM install), so `/etc/kernel/cmdline` and `proxmox-boot-tool refresh` do not apply:

   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt initcall_blacklist=sysfb_init"
   ```

   `initcall_blacklist=sysfb_init` keeps the host from claiming the boot framebuffer on the iGPU, which is what costs the local console.
3. Load the VFIO modules, in `/etc/modules`:

   ```
   vfio
   vfio_iommu_type1
   vfio_pci
   ```

4. Hand the iGPU to `vfio-pci` instead of `i915`, in `/etc/modprobe.d/vfio.conf`. The ID comes from `lspci -nn -s 00:02.0` (`8086:4680` for the UHD 770 of the i5-12600K):

   ```
   options vfio-pci ids=8086:4680
   softdep i915 pre: vfio-pci
   blacklist i915
   ```

5. `update-initramfs -u -k all` and reboot the host. This stops every guest on it.
6. Check:

   ```bash
   dmesg | grep -e DMAR -e IOMMU    # "IOMMU enabled"
   lspci -nnk -s 00:02.0            # "Kernel driver in use: vfio-pci"
   ```

### VM

The VM has to be OVMF/`q35` (the NixOS template is) and loses memory ballooning, since passthrough pins all of its RAM. The virtual display stays, so the Proxmox console keeps working.

```bash
qm set <vmid> --hostpci0 0000:00:02.0,pcie=1 --balloon 0
qm shutdown <vmid> && qm start <vmid>   # a reboot from inside the guest does not pick up the device
```

### Guest

`storage-node` carries the firmware, the VAAPI driver and the test tools in its `configuration.nix`. Validate with:

```bash
lspci -nnk | grep -A3 VGA                                   # second VGA device, driver i915
ls /dev/dri                                                 # card0 (virtual), card1 + renderD128 (iGPU)
sudo dmesg | grep -i -E "i915|guc|huc"                      # firmware loaded, no errors
vainfo --display drm --device /dev/dri/renderD128           # lists H.264/HEVC/AV1 profiles
sudo intel_gpu_top                                          # shows load during a transcode
```

The iGPU shows up at `01:00.0` in the guest. `Failed to find VBIOS tables (VBT)`, `ROM ... can't assign` and `Cannot find any crtc or sizes` in `dmesg` are expected: there is no display attached and none is needed for transcoding.

### Rollback

`qm set <vmid> --delete hostpci0`, remove `/etc/modprobe.d/vfio.conf`, take the three parameters off the kernel command line, then `update-grub`, `update-initramfs -u -k all` and reboot.

> [!NOTE]
> Exact mount points and LVM configurations will be documented here once fully finalized.

## USB Passthrough

The HP ScanJet Pro 2600 f1 is plugged into `vault` and passed through to `storage-node` (VM 891) for the scanner service. Like the other passthroughs it is set up by hand on the host.

It is passed by vendor/product ID rather than by port, so it keeps working when it is moved to another port:

```bash
lsusb | grep 03f0                 # on vault: 03f0:6105 HP ScanJet Pro 2600 f1
qm set 891 --usb0 host=03f0:6105
```

USB is hotpluggable, so the VM does not need a restart. The scanner may be switched off or asleep when the VM starts; QEMU attaches it as soon as it appears. To bind a physical port instead of the device, use `host=<bus>-<port>` (from `lsusb -t`).

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
| Firmware | OVMF (UEFI), machine `q35` | For all new VMs: EFI disk on `local-lvm`, "Pre-Enroll keys" unticked (Secure Boot would reject systemd-boot). The NixOS template (`nodes/nixos-base/`) is built this way. Existing VMs stay on SeaBIOS with GRUB; migrating them is not worth the effort. |

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

