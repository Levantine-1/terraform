# cameras runs ZoneMinder: RTSP ingestion, continuous recording, live
# streaming, and event storage for the guinea pig cage cameras. Defined
# separately from the shared vms_fx8200 for_each loop in vms.tf (like
# service.tf) because it needs a second disk -- none of the other FX8200
# VMs do, so forcing it into that shared loop would mean either attaching
# a 2TB disk to every VM there or a conditional dynamic block. A dedicated
# resource is simpler and matches this repo's existing precedent for a VM
# whose shape diverges from the standard pattern.
#
# LAN-only: no second NIC, no public exposure. The public-facing piece
# (livecam.levantine.io) is a separate container on dockerhost1 that talks
# to this VM's ZoneMinder over the internal LAN -- see the livecam repo.
resource "proxmox_virtual_environment_vm" "cameras" {
  provider  = proxmox.host2
  name      = "cameras"
  node_name = var.proxmox_node_host2
  vm_id     = 201

  # Auto-start on hypervisor boot -- see service.tf's on_boot comment for
  # why (2026-08-20 fleet-wide outage from a host reboot).
  on_boot = true

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    # host, not the default qemu64 -- see vms.tf's matching comment for why.
    type = "host"
  }

  memory {
    # Deliberately conservative starting point, not a guess-large number:
    # ZoneMinder's Function=Record mode (no motion analysis) plus direct/
    # passthrough recording (see roles/applications/camera_nvr) should be
    # light. Resize later against real node_exporter/Prometheus numbers
    # once it's running, the same way dockerhost1 and kube-c-00 were both
    # right-sized off measured peak load, not guesses.
    dedicated = 2048
  }

  scsi_hardware = "virtio-scsi-pci"

  # OS disk -- SSD-backed local-lvm, matches every other FX8200 VM.
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.debian_cloud_image_host2.id
    interface    = "scsi0"
    size         = 16
    file_format  = "raw"
  }

  # Footage disk -- the new 2TB HDD, its own separate Proxmox storage pool
  # (created manually on the host, see roles/applications/camera_nvr's
  # README -- terraform never creates storage pools anywhere in this repo,
  # every existing pool is pre-existing and only referenced by
  # datastore_id string). No RAID/mirroring: data integrity on this disk
  # is explicitly not a priority, it gets run until it dies and swapped.
  disk {
    datastore_id = "nvr-hdd"
    interface    = "scsi1"
    size         = 1900
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
        address = "192.168.1.85/24"
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
