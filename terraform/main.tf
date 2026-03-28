resource "proxmox_vm_qemu" "test_nixos" {
  name        = "test-nixos-vm"
  target_node = "phil"
  clone       = "119" # The ID of your NixOS template

  # Basic Resources
  cores    = 2
  memory   = 4096
  vm_state = "running"
  onboot   = true
  agent    = 0 # Set to 1 only if QEMU Guest Agent is installed in the template

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
