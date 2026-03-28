resource "proxmox_vm_qemu" "test_nixos" {
  name        = "test-nixos-vm"
  target_node = "phil"
  clone       = "119" # The ID of your NixOS template

  # Basic Resources
  cpu {
    cores = 2
  }
  memory   = 4096
  vm_state = "running"
  onboot   = true
  agent    = 0

  # Disk Configuration
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "16G"
          storage = "local-lvm"
        }
      }
    }
  }

  # Network Configuration
  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Lifecycle to prevent unexpected reboots
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
