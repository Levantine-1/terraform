# frigate runs Frigate NVR: RTSP ingestion via its bundled go2rtc,
# continuous recording to the 2TB HDD, and the timeline/scrub/export UI.
# It replaces ZoneMinder, which recorded correctly but is event-oriented
# rather than timeline-oriented -- no continuous scrub bar, no live
# previews on the console -- and was the heaviest thing on the old VM
# (two zmc processes at ~415MB RSS each, plus Apache and MariaDB).
#
# Defined separately from the shared vms_fx8200 for_each loop in vms.tf
# (like service.tf) because it needs a second disk -- none of the other
# FX8200 VMs do, so forcing it into that shared loop would mean either
# attaching a 2TB disk to every VM there or a conditional dynamic block.
#
# LAN-only: no second NIC, no public exposure. The public-facing piece
# (livecam.levantine.io) is a separate container on dockerhost1; it serves
# live view from this VM's go2rtc and proxies Frigate's UI behind its own
# login -- see the livecam repo.
resource "proxmox_virtual_environment_vm" "frigate" {
  provider  = proxmox.host2
  name      = "frigate"
  node_name = var.proxmox_node_host2
  vm_id     = 202

  # Auto-start on hypervisor boot -- see service.tf's on_boot comment for
  # why (2026-08-20 fleet-wide outage from a host reboot).
  on_boot = true

  agent {
    enabled = false
  }

  cpu {
    # Measured, not guessed: both cameras recording with detection off and
    # decoding confined to the 704x480 substream sit at 22-27% of a 2-core
    # VM, spiking to ~85% while previews are generated. 4 cores keeps those
    # spikes well clear of saturation on a 2012-era CPU.
    cores = 4
    # host, not the default qemu64 -- see vms.tf's matching comment for why.
    type = "host"
  }

  memory {
    # Frigate measured at ~742MB RSS for both cameras during a live smoke
    # test on this exact hardware. 4096 leaves room for the page cache the
    # recording writes churn through and for the /tmp/cache tmpfs. Recheck
    # against real node_exporter numbers after a day and resize, the same
    # way dockerhost1 and kube-c-00 were right-sized off measured peak.
    dedicated = 4096
  }

  scsi_hardware = "virtio-scsi-pci"

  # OS disk -- SSD-backed local-lvm, matches every other FX8200 VM. 32GB
  # rather than the usual 16: the Frigate image alone is 7.5GB pulled, so
  # 16 would leave almost nothing for the OS, logs and a second image
  # version during an upgrade.
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.debian_cloud_image_host2.id
    interface    = "scsi0"
    size         = 32
    file_format  = "raw"
  }

  # Footage disk -- the 2TB HDD, its own separate Proxmox storage pool
  # (created manually on the host, see roles/applications/frigate's
  # README -- terraform never creates storage pools anywhere in this repo,
  # every existing pool is pre-existing and only referenced by
  # datastore_id string). No RAID/mirroring: data integrity on this disk
  # is explicitly not a priority, it gets run until it dies and swapped.
  disk {
    datastore_id = "nvr-hdd"
    interface    = "scsi1"
    # 1900 GiB on a 1832 GiB physical volume. This is overprovisioned, and it
    # cannot be corrected here: virtual disks cannot be shrunk without
    # recreating them, which would destroy the footage. So the guest can
    # believe it has space the host cannot supply, and the RETENTION WINDOW is
    # what has to keep real usage inside what the host can back -- see
    # frigate_retain_days in ansible's frigate role. Do not "fix" this by
    # lowering the number.
    size         = 1900
    file_format  = "raw"
    # Without this QEMU drops the guest's TRIM/discard, so when Frigate ages
    # footage out the freed blocks are never punched back to the sparse image
    # and its real footprint on /mnt/nvr-hdd only ever grows. fstrim.timer is
    # already enabled inside the guest, so this is the missing half.
    discard      = "on"
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
        address = "192.168.1.86/24"
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
