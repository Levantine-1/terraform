# All other VMs in the fleet: single NIC on the internal LAN (vmbr1), same
# cloud-init pattern (automation user/key, static IP, virtio-scsi disk on
# SSD1TB). service (vm_id 103) is defined separately in service.tf since
# it's dual-NIC and has no dependencies.
locals {
  vms = {
    vmwarebastion = { vm_id = 107, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.10/24" }
    dockerhost1   = { vm_id = 105, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.31/24" }
    splunk        = { vm_id = 106, cores = 2, memory = 4096, disk_size = 32, ip_address = "192.168.1.21/24" }
    pxdbc1        = { vm_id = 108, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.61/24" }
    pxdbc2        = { vm_id = 109, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.62/24" }
    pxdbc3        = { vm_id = 110, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.63/24" }
    proxysql      = { vm_id = 111, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.71/24" }
    kube-c-00     = { vm_id = 112, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.80/24" }
    kube-w-00     = { vm_id = 113, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.90/24" }
    kube-w-01     = { vm_id = 114, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.91/24" }
  }
}

resource "proxmox_virtual_environment_vm" "vms" {
  for_each = local.vms

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  scsi_hardware = "virtio-scsi-pci"

  disk {
    datastore_id = "SSD1TB"
    file_id      = proxmox_download_file.debian_cloud_image.id
    interface    = "scsi0"
    size         = each.value.disk_size
    file_format  = "raw"
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
        address = each.value.ip_address
        gateway = "192.168.1.1"
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
      # These VMs' disks predate this module (weren't created by terraform),
      # so imported state has no file_id -- ignoring it stops terraform
      # trying to "fix" that by destroying and recreating the disk. Only
      # affects updates to the existing disk; a genuinely fresh VM created
      # by this resource still gets file_id at creation time as normal.
      disk[0].file_id,
    ]
  }
}
