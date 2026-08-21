# Shared base image for dockerhost1/vmwarebastion (host1) -- downloaded
# fresh by terraform rather than depending on some pre-existing local file,
# so a from-scratch rebuild doesn't need any manual staging on the Proxmox
# host.
#
# NOT used by `service` -- found the hard way that sharing this resource
# with `service` is dangerous: `terraform destroy -target=<any VM using
# this image>` pulls in every OTHER consumer of the same image resource
# too (confirmed via a real dry-run plan, not a guess), including `service`
# itself, defeating rebuild_fleet.sh's entire premise of never touching it.
# `service` gets its own dedicated copy below instead, at zero real cost
# (same public image, downloaded twice) specifically to keep it fully
# decoupled from anything targeted for destroy.
resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  file_name    = "debian-12-generic-amd64.img"
  overwrite    = false
}

# `service`'s own dedicated copy -- see the comment above for why this
# can't be the same resource as debian_cloud_image, despite being the
# identical image.
resource "proxmox_download_file" "debian_cloud_image_service" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  file_name    = "debian-12-generic-amd64-service.img"
  overwrite    = false
}

# Same image, downloaded separately onto the second host -- a file_id only
# resolves within the node/storage it was downloaded to, so this isn't
# shareable across the two (non-clustered) hosts.
resource "proxmox_download_file" "debian_cloud_image_host2" {
  provider     = proxmox.host2
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node_host2
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  file_name    = "debian-12-generic-amd64.img"
  overwrite    = false
}
