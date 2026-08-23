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
#
# This resource has never actually been applied (absent from terraform
# state) -- the running VM was created by hand, before this file was
# written, from an installer image someone downloaded and staged on the
# `local` datastore directly. This declaration exists purely so a real
# rebuild has a starting point, not as a description of how the current VM
# came to exist.
#
# The version below (26.1.6) was read off the ISO actually staged on the
# datastore (`OPNsense-26.1.6-serial-amd64.img`), not confirmed against the
# live VM's patched version -- OPNsense updates in place, so the running
# instance may be newer. Confirm the current release and this URL's shape
# against https://opnsense.org/download/ before ever relying on this for a
# real rebuild; treat it as a starting point, not a tested value.
resource "proxmox_download_file" "opnsense_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://mirror.dns-root.de/opnsense/releases/26.1/OPNsense-26.1.6-serial-amd64.iso.bz2"
  file_name    = "OPNsense-26.1.6-serial-amd64.iso"
  # NOTE: OPNsense only publishes bz2-compressed images. This assumes the
  # bpg/proxmox provider's decompression support (mirroring Proxmox's own
  # download-from-url API); verify against the current provider docs before
  # the first real `terraform apply` of this resource -- unverified as of
  # this writing.
  decompression_algorithm = "bz2"
  overwrite                = false
}

# KNOWN DRIFT, LEFT DELIBERATELY UNAPPLIED: `terraform plan` on this
# resource is not clean, and that is expected. Imported from the hand-built
# VM, whose real config differs from what is declared below in ways that
# would need the router stopped to reconcile:
#
#   cpu.type       real: qemu64   declared: host   (see vms.tf's cpu.type
#     comment for why "host" is correct -- it is a verified fix for an AVX
#     instruction-set bug, applied to dockerhost1 after it broke a running
#     container. Not yet applied here because it needs a stop/start, and
#     this VM is the router: taking it down needs a deliberate window, not
#     an incidental side effect of an unrelated apply.)
#   disk.interface real: sata1    declared: sata0  (moving a live boot
#     disk's controller slot is the genuinely risky one of this set --
#     don't apply this without understanding exactly what Proxmox does to
#     the existing disk when it changes.)
#   cdrom / boot_order -- real VM currently has neither (the install media
#     was detached after setup completed); declared here purely as the
#     shape a fresh rebuild would need.
#
# scsi_hardware / vga / operating_system also show as drift but are cosmetic
# metadata with no boot-time effect either way.
#
# Never run an unscoped `terraform apply` against this resource. If the
# cpu.type/disk changes are ever wanted for real, that is a scheduled,
# backed-up, router-offline maintenance action -- not something to do
# because a plan happened to mention it.
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

  # SATA, not virtio-scsi like the Linux VMs (BSD's virtio-blk/scsi driver
  # support is less of a given than on Linux). The interface slot below
  # (sata0) is the target for a fresh install, not what the live VM
  # currently uses -- see the drift note above the resource block.
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
