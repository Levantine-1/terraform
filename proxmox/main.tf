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

# Second, separate (non-clustered) Proxmox host. It also reports node name
# "pve" (the OS default) -- the two hosts are only distinguishable by which
# API endpoint you're talking to, so this is a genuinely separate provider
# instance, not just a different node_name on the same one.
variable "proxmox_endpoint_host2" {
  default = "https://10.69.69.116:8006/"
}

variable "proxmox_node_host2" {
  default = "pve"
}

# Same automation user/key every host in this fleet already trusts
# (matches aws_key_pair.automation_key_pair in the ec2 module)
variable "automation_ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlK9SYgHttisI9NMozvE0HNroEK2bBG406szUfIGz1Xq+CGTdW1x197nBh36zqa5gYbhQCM/uGKOaGCPB+6R6gW0CpaHjPvcKW+pKAUaEWkQzeRYaS1yEJjD4Fh+DFqgaYKh+VTCH7RC2c6N+YdKKJkaSan2iaI9Z5nLjAxJloepbJBTDnhPQVasqNUykh6ZbYyYM5p3EEhYPrw5bMZJJkyHV44UexfqBmroSgbA87PtyUw/+9T9aG3yYwtAafUZJlZpWbeHdMRW/SVYmt/wCze5x+IAxqjk+48b8HeltR5Nys33VSQybuKNrcnumDNzthLFMQvF4ABO66yCTQ5NaBQ== automation"
}

# Break-glass path for the hard disaster-recovery scenario (see
# ansible/docs/disaster-recovery.md): a from-scratch rebuild starts with
# no Vault to read credentials from at all (Vault's own VM is one of the
# things being created), so the very first apply -- creating just the
# Vault/OPNsense/pi-hole VMs -- can't depend on Vault being reachable.
# Defaults to false (normal operation, unaffected): every other apply
# still reads from Vault as always. Only set true, with the three
# override vars supplied directly, for that one bootstrap apply against
# the primary host (10.69.69.116/host2 is untouched by this -- it hosts
# nothing needed before Vault exists).
variable "proxmox_bootstrap_mode" {
  description = "True only for the initial break-glass apply when Vault doesn't exist yet."
  type        = bool
  default     = false
}

variable "proxmox_api_token_override" {
  default   = ""
  sensitive = true
}

variable "proxmox_ssh_username_override" {
  default = ""
}

variable "proxmox_ssh_password_override" {
  default   = ""
  sensitive = true
}

# Proxmox token is stored in Vault (kv/data/proxmox/api_token), same pattern
# as the AWS credentials -- the vault_token var/provider is inherited from
# the root module. `count` (not just an inline conditional on the value)
# so this data source isn't evaluated at all in bootstrap mode -- Terraform
# evaluates every declared data source regardless of whether its result is
# actually used, so simply ignoring the value wouldn't be enough to avoid
# needing a reachable Vault.
data "vault_generic_secret" "proxmox_token" {
  count = var.proxmox_bootstrap_mode ? 0 : 1
  path  = "kv/proxmox/api_token"
}

# The provider needs direct node SSH access too: some disk operations (e.g.
# converting a downloaded image onto LVM-backed storage like SSD1TB, which
# isn't file-based) have no Proxmox API equivalent, so the provider falls
# back to SSH-ing into the node itself.
data "vault_generic_secret" "proxmox_node_ssh" {
  count = var.proxmox_bootstrap_mode ? 0 : 1
  path  = "kv/proxmox/node_ssh"
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_bootstrap_mode ? var.proxmox_api_token_override : (
    "${data.vault_generic_secret.proxmox_token[0].data["token_id"]}=${data.vault_generic_secret.proxmox_token[0].data["token_secret"]}"
  )
  insecure = true

  ssh {
    agent    = false
    username = var.proxmox_bootstrap_mode ? var.proxmox_ssh_username_override : data.vault_generic_secret.proxmox_node_ssh[0].data["username"]
    password = var.proxmox_bootstrap_mode ? var.proxmox_ssh_password_override : data.vault_generic_secret.proxmox_node_ssh[0].data["password"]
  }
}

# Credentials for the second host, same pattern as above (mirrors the
# aws.delegate alias pattern used in ec2/instances and route53/hosted_zones
# for the subdomain-delegation AWS account).
data "vault_generic_secret" "proxmox_token_host2" {
  path = "kv/proxmox/host2/api_token"
}

data "vault_generic_secret" "proxmox_node_ssh_host2" {
  path = "kv/proxmox/host2/node_ssh"
}

provider "proxmox" {
  alias     = "host2"
  endpoint  = var.proxmox_endpoint_host2
  api_token = "${data.vault_generic_secret.proxmox_token_host2.data["token_id"]}=${data.vault_generic_secret.proxmox_token_host2.data["token_secret"]}"
  insecure  = true

  ssh {
    agent    = false
    username = data.vault_generic_secret.proxmox_node_ssh_host2.data["username"]
    password = data.vault_generic_secret.proxmox_node_ssh_host2.data["password"]
  }
}
