# Jenkins -- dual-NIC like service (net0 external on vmbr0, net1 internal
# on vmbr1), since it's reachable both from the internal LAN and externally
# via its own netplan config. Previously an ESXi-imported disk with no
# install automation; now a fresh cloud-init VM provisioned by
# roles/applications/jenkins/install.yml.
resource "proxmox_virtual_environment_vm" "jenkins" {
  name      = "jenkins"
  node_name = var.proxmox_node
  vm_id     = 201

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
    size         = 25
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
        address = "10.69.69.20/24"
        gateway = "10.69.69.1"
      }
    }

    ip_config {
      ipv4 {
        address = "192.168.1.20/24"
      }
    }

    dns {
      servers = ["192.168.1.2", "1.1.1.1"]
    }

    user_account {
      username = "automation"
      keys     = [var.automation_ssh_public_key]
    }
  }

  on_boot = false

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
      network_device[1].mac_address,
      disk[0].file_id,
    ]
  }
}
