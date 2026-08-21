# VMs that stay on the original host (10.69.69.139). Single NIC on the
# internal LAN (vmbr1), same cloud-init pattern (automation user/key, static
# IP, virtio-scsi disk on SSD1TB). service (vm_id 103) is defined separately
# in service.tf since it's dual-NIC and has no dependencies.
locals {
  vms = {
    vmwarebastion = { vm_id = 107, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.10/24" }
    # Bumped from cores=2/memory=2048: it hosts 9 concurrent self-hosted
    # GitHub Actions runners (one per app repo) plus their Docker builds --
    # the original sizing hit ~85% I/O pressure and memory pinned at its
    # ceiling under concurrent CI load, causing runners to flap offline.
    dockerhost1   = { vm_id = 105, cores = 8, memory = 16384, disk_size = 16, ip_address = "192.168.1.31/24" }
  }
}

# VMs migrated to the second host (10.69.69.116) via manual vzdump
# backup/restore, now brought back under terraform. Same vm_id/ip_address as
# before the migration -- only physical placement (node/provider/datastore)
# changed.
locals {
  vms_fx8200 = {
    pxdbc1    = { vm_id = 108, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.61/24" }
    pxdbc2    = { vm_id = 109, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.62/24" }
    pxdbc3    = { vm_id = 110, cores = 2, memory = 2048, disk_size = 16, ip_address = "192.168.1.63/24" }
    proxysql  = { vm_id = 111, cores = 1, memory = 1024, disk_size = 8, ip_address = "192.168.1.71/24" }
    kube-c-00 = { vm_id = 112, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.80/24" }
    # kube-w-00/kube-w-01 scaled down (2026-08-17): this cluster only exists
    # as a portfolio tech demo (hosts DataGateway, a single low-traffic
    # Spring middleman service) -- it was idling at 3 full nodes with zero
    # workload deployed. kube-c-00 alone now runs the demo single-node (see
    # the control-plane untaint task in configure_control_plane.yml).
    # To restore the full 3-node demo state: uncomment these two lines,
    # uncomment the matching entries in ansible's production.ini
    # [DataGatewayK8Cluster] group, `terraform apply`, then re-run
    # roles/os_configs/kubernetes_clusters_baseline (or app.yml) to join
    # them.
    # kube-w-00 = { vm_id = 113, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.90/24" }
    # kube-w-01 = { vm_id = 114, cores = 2, memory = 4096, disk_size = 20, ip_address = "192.168.1.91/24" }
    # theia was an ESXi-imported disk with no install automation; now a
    # fresh cloud-init VM provisioned by roles/applications/theia/install.yml.
    # Bumped to 16G from its original 10G since it's a fresh build anyway
    # (MariaDB + RabbitMQ + app need more headroom than the original had).
    theia = { vm_id = 200, cores = 1, memory = 2048, disk_size = 16, ip_address = "192.168.1.30/24" }
  }
}

resource "proxmox_virtual_environment_vm" "vms" {
  for_each = local.vms

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  # Auto-start on hypervisor boot -- see service.tf's on_boot comment for
  # why (2026-08-20 fleet-wide outage from a host reboot).
  on_boot   = true

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

resource "proxmox_virtual_environment_vm" "vms_fx8200" {
  provider = proxmox.host2
  for_each = local.vms_fx8200

  name      = each.key
  node_name = var.proxmox_node_host2
  vm_id     = each.value.vm_id
  # Auto-start on hypervisor boot -- see service.tf's on_boot comment for
  # why (2026-08-20 fleet-wide outage from a host reboot).
  on_boot   = true

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
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.debian_cloud_image_host2.id
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
    datastore_id = "local-lvm"

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
      # Proxmox auto-assigns the MAC on creation -- don't fight over it.
      network_device[0].mac_address,
    ]
  }
}
