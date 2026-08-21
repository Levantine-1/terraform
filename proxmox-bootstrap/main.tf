# Break-glass terraform config for Scenario B (hard DR / total physical
# host loss) in ansible/docs/disaster-recovery.md.
#
# `proxmox/main.tf` (the normal fleet config) reads Proxmox API credentials
# AND AWS credentials from Vault -- terraform configures every declared
# provider block eagerly, even under `-target`, so that's true even for an
# apply that only touches Proxmox resources. If Vault is one of the things
# that needs rebuilding, that config simply cannot run: no Vault means no
# credentials means no way to create the VM that would bring Vault back.
#
# This config breaks that circularity by never referencing Vault or AWS at
# all -- Proxmox credentials come in as plain input variables, supplied by
# hand from a freshly-installed Proxmox's own UI/CLI (Datacenter -> API
# Tokens; root SSH password is whatever was set during the Proxmox install).
# It creates ONLY the four critical-tier VM shells (vault, opnsense,
# pi-hole, service) -- nothing else needs this treatment, since every other
# host is created by `proxmox/main.tf` once Vault is back up.
#
# State is local, not S3: this only ever runs once per real incident, gets
# reconciled into the main module's state immediately afterward (see
# RECONCILIATION.md in this directory), and shouldn't need AWS credentials
# just to exist. Delete terraform.tfstate here once reconciliation is done.
#
# Resource shapes below are intentionally duplicated from
# proxmox/vms.tf, proxmox/service.tf, and proxmox/opnsense.tf rather than
# sharing code with them -- this config must stand alone with zero
# dependency on anything Vault-flavored, including shared modules that
# happen to live next to Vault-dependent code. Keep them in sync by hand if
# those specs change; this is break-glass code, expected to be touched
# rarely and read carefully when it is.

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

variable "proxmox_endpoint" {
  default = "https://10.69.69.139:8006/"
}

variable "proxmox_node" {
  default = "pve"
}

variable "proxmox_api_token_id" {
  description = "Datacenter -> Permissions -> API Tokens in the fresh Proxmox UI. Format: user@realm!tokenname"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  sensitive = true
}

variable "proxmox_ssh_username" {
  description = "Needed for disk operations with no API equivalent (see proxmox/main.tf's matching comment). Usually root."
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "Whatever was set during the Proxmox install."
  sensitive   = true
}

variable "automation_ssh_public_key" {
  description = "Same key every host in the fleet already trusts -- not a secret, safe to keep as a default here."
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlK9SYgHttisI9NMozvE0HNroEK2bBG406szUfIGz1Xq+CGTdW1x197nBh36zqa5gYbhQCM/uGKOaGCPB+6R6gW0CpaHjPvcKW+pKAUaEWkQzeRYaS1yEJjD4Fh+DFqgaYKh+VTCH7RC2c6N+YdKKJkaSan2iaI9Z5nLjAxJloepbJBTDnhPQVasqNUykh6ZbYyYM5p3EEhYPrw5bMZJJkyHV44UexfqBmroSgbA87PtyUw/+9T9aG3yYwtAafUZJlZpWbeHdMRW/SVYmt/wCze5x+IAxqjk+48b8HeltR5Nys33VSQybuKNrcnumDNzthLFMQvF4ABO66yCTQ5NaBQ== automation"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true

  ssh {
    agent    = false
    username = var.proxmox_ssh_username
    password = var.proxmox_ssh_password
  }
}
