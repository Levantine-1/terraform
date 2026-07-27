# service is the control plane -- terraform, ansible, and this whole repo
# clone live here. It's deliberately the only VM with no dependencies on
# anything else in this config, and dual-NIC like jenkins (net0 external
# static on vmbr0, net1 internal static on vmbr1) so it's directly reachable
# from outside the internal VM LAN without needing another host as a relay
# hop -- this is what makes it viable as the control plane/orchestrator.
resource "proxmox_virtual_environment_vm" "service" {
  name      = "service"
  node_name = var.proxmox_node
  vm_id     = 103
  on_boot   = false

  agent {
    enabled = false
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  scsi_hardware = "virtio-scsi-pci"

  disk {
    datastore_id = "SSD1TB"
    file_id      = proxmox_download_file.debian_cloud_image.id
    interface    = "scsi0"
    size         = 16
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
  }

  network_device {
    bridge = "vmbr1"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = "SSD1TB"

    ip_config {
      ipv4 {
        address = "10.69.69.21/24"
        gateway = "10.69.69.1"
      }
    }

    ip_config {
      ipv4 {
        address = "192.168.1.50/24"
      }
    }

    dns {
      servers = ["1.1.1.1"]
    }

    user_account {
      username = "automation"
      keys     = [var.automation_ssh_public_key]
    }
  }

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
      network_device[1].mac_address,
      # This VM's disk wasn't created by terraform (predates this module),
      # so imported state has no file_id -- ignoring it stops terraform
      # trying to "fix" that by destroying and recreating the disk. Only
      # affects updates to the existing disk; a genuinely fresh VM created
      # by this resource still gets file_id at creation time as normal.
      disk[0].file_id,
    ]
  }
}
