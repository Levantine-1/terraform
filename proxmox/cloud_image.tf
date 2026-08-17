# Shared base image for every VM in this fleet -- downloaded fresh by
# terraform rather than depending on some pre-existing local file, so a
# from-scratch rebuild doesn't need any manual staging on the Proxmox host.
resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  file_name    = "debian-12-generic-amd64.img"
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
