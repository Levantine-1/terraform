# OPNsense (router/firewall/DNS for the whole 192.168.1.0/24 internal
# network) was hand-built and predates this module -- it's FreeBSD-based,
# not the Debian cloud-init pattern every other VM in this fleet uses, and
# there's no unattended-install mechanism for it (confirmed: no prior art
# anywhere in this repo or the ansible repo). Terraform's job here stops at
# creating the VM shell with the installer ISO attached -- the actual
# install is a deliberate manual step (connect via Proxmox's console,
# complete the OPNsense installer interactively), after which
# roles/applications/opnsense's restore script pushes the latest committed
# config.xml back via OPNsense's API.
#
# Never included in rebuild_fleet.sh's destroy/rebuild cycle -- it's the
# router for the whole internal network; destroying it cuts off access to
# everything else on 192.168.1.0/24, including the ability to SSH into any
# other host to fix it.
resource "proxmox_download_file" "opnsense_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://mirror.dns-root.de/opnsense/releases/25.1/OPNsense-25.1-serial-amd64.iso.bz2"
  file_name    = "OPNsense-25.1-serial-amd64.iso"
  # NOTE: OPNsense only publishes bz2-compressed images. This assumes the
  # bpg/proxmox provider's decompression support (mirroring Proxmox's own
  # download-from-url API); verify against the current provider docs and
  # the actual current OPNsense release version before the first real
  # `terraform apply` of this resource -- unverified as of this writing.
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

  # SATA, not virtio-scsi like the Linux VMs -- matches the live host's
  # current disk interface (BSD's virtio-blk/scsi driver support is less
  # of a given than on Linux; SATA is what the existing install actually
  # uses).
  disk {
    datastore_id = "SSD1TB"
    interface    = "sata0"
    size         = 8
    file_format  = "raw"
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_download_file.opnsense_iso.id
    interface = "ide2"
  }

  # sata0 first so a completed install boots straight from disk; falls
  # through to the attached ISO (ide2) on first boot since an empty disk
  # reports as not bootable.
  boot_order = ["sata0", "ide2"]

  # WAN (home LAN, 10.69.69.0/24) + LAN (internal, 192.168.1.0/24) --
  # matches the live host's net0/net1 split. e1000, not virtio, again
  # matching the existing install.
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

  # No `initialization` block -- OPNsense doesn't support cloud-init, so
  # network/user config genuinely has to happen through the installer and
  # the config.xml restore, not this resource.

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
      network_device[1].mac_address,
    ]
  }
}
