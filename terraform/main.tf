resource "proxmox_vm_qemu" "test_nixos" {
  name        = "test-nixos-vm"
  vmid        = 801 # Fixed ID ensures Terraform won't create duplicates
  target_node = "phil"
  clone_id    = 119
  full_clone  = true

  # Basic Resources
  cpu {
    cores = 2
  }
  memory   = 4096
  vm_state = "running"
  start_at_node_boot = true
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
