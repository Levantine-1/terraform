# Own dedicated copy of the Debian cloud image -- not shared with anything
# in proxmox/main.tf, since that config won't even exist as far as this one
# is concerned (see main.tf's header comment).
resource "proxmox_download_file" "debian_cloud_image_bootstrap" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  file_name    = "debian-12-generic-amd64-bootstrap.img"
  overwrite    = false
}

# vault and pi-hole: same shape as proxmox/vms.tf's local.vms pattern
# (single NIC, static IP, small disk). service is dual-NIC and gets its own
# resource below, matching proxmox/service.tf.
locals {
  critical_tier_vms = {
    pi-hole = { vm_id = 102, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.2/24" }
    vault   = { vm_id = 104, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.41/24" }
  }
}

resource "proxmox_virtual_environment_vm" "critical_tier_vms" {
  for_each = local.critical_tier_vms

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  on_boot   = true

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  scsi_hardware = "virtio-scsi-pci"

  disk {
    datastore_id = "SSD1TB"
    file_id      = proxmox_download_file.debian_cloud_image_bootstrap.id
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
    ]
  }
}

# service: matches proxmox/service.tf. Dual-NIC (net0 external/dhcp on
# vmbr0, net1 internal static on vmbr1) so it's directly reachable without
# another host as a relay -- same reasoning as the main config, since
# service is still the control plane once this stage is done.
resource "proxmox_virtual_environment_vm" "service" {
  name      = "service"
  node_name = var.proxmox_node
  vm_id     = 103
  on_boot   = true

  agent {
    enabled = false
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 6144
  }

  scsi_hardware = "virtio-scsi-pci"

  disk {
    datastore_id = "SSD1TB"
    file_id      = proxmox_download_file.debian_cloud_image_bootstrap.id
    interface    = "scsi0"
    size         = 50
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
        address = "dhcp"
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
    ]
  }
}

# opnsense: matches proxmox/opnsense.tf exactly -- VM shell + installer ISO
# only. The actual install is still a manual step (Proxmox console,
# interactive installer), same as normal operation -- see that file's
# header comment for why no unattended path exists.
resource "proxmox_download_file" "opnsense_iso_bootstrap" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://mirror.dns-root.de/opnsense/releases/25.1/OPNsense-25.1-serial-amd64.iso.bz2"
  file_name    = "OPNsense-25.1-serial-amd64-bootstrap.iso"
  decompression_algorithm = "bz2"
  overwrite                = false
}

resource "proxmox_virtual_environment_vm" "opnsense" {
  name      = "opnsense"
  node_name = var.proxmox_node
  vm_id     = 101
  on_boot   = true

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "SSD1TB"
    interface    = "sata0"
    size         = 8
    file_format  = "raw"
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_download_file.opnsense_iso_bootstrap.id
    interface = "ide2"
  }

  boot_order = ["sata0", "ide2"]

  network_device {
    bridge = "vmbr0"
    model  = "e1000"
  }

  network_device {
    bridge = "vmbr1"
    model  = "e1000"
  }

  operating_system {
    type = "other"
  }

  serial_device {}

  vga {
    type = "std"
  }

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
      network_device[1].mac_address,
    ]
  }
}
