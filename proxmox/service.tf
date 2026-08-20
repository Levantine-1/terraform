# service is the control plane -- terraform, ansible, and this whole repo
# clone live here. It's deliberately the only VM with no dependencies on
# anything else in this config, and dual-NIC (net0 external on vmbr0, net1
# internal static on vmbr1) so it's directly reachable from outside the
# internal VM LAN without needing another host as a relay hop -- this is
# what makes it viable as the control plane/orchestrator.
#
# net0 is left on dhcp (not statically pinned) deliberately: this VM
# already has cloud-init network management disabled
# (99-disable-network-config.cfg, from the cloud-init-reset incident), so a
# declared ip_config here is never actually applied by the guest -- it would
# just be permanent drift in terraform's view of reality. If a stable
# address is needed later, set a DHCP static reservation for this VM's MAC
# on the router/OPNsense instead of fighting cloud-init here.
resource "proxmox_virtual_environment_vm" "service" {
  name      = "service"
  node_name = var.proxmox_node
  vm_id     = 103
  # Auto-start on hypervisor boot -- service is the control plane, and a
  # host reboot with on_boot=false left the entire fleet down until this
  # was noticed and every VM started by hand (2026-08-20 incident).
  on_boot   = true

  agent {
    enabled = false
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 6144
  }

  scsi_hardware = "virtio-scsi-pci"

  # Resized 2 core/2GB/16GB -> 4 core/6GB/50GB to host the ops stack
  # directly on service instead of separate VMs: Semaphore UI, Prometheus/
  # Grafana/Alertmanager/Loki, and Zammad (no Elasticsearch -- unnecessary
  # for a low ticket volume homelab, and the single biggest resource cost).
  disk {
    datastore_id = "SSD1TB"
    file_id      = proxmox_download_file.debian_cloud_image.id
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
      # This VM's disk wasn't created by terraform (predates this module),
      # so imported state has no file_id -- ignoring it stops terraform
      # trying to "fix" that by destroying and recreating the disk. Only
      # affects updates to the existing disk; a genuinely fresh VM created
      # by this resource still gets file_id at creation time as normal.
      disk[0].file_id,
      # Purely cosmetic: the provider wants to write computed defaults
      # (timeout/trim/type) into state for this already-matching block.
      # Not worth it -- any apply against this resource stops the VM
      # (confirmed: even this no-op diff triggered a stop/start), which
      # wipes non-persistent DNS/hosts state and forces a re-run of
      # configure_DNS_Resolver.yml + configureHostFile.yml to recover.
      agent,
    ]
  }
}
