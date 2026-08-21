# Break-glass: rebuilding the critical tier with no Vault

Use this only for `ansible/docs/disaster-recovery.md`'s Scenario B (total
physical host loss). If Vault/`service`/OPNsense/pi-hole are all still
reachable, you don't need this directory — use the normal
`terraform/proxmox` config instead.

See `main.tf`'s header comment for *why* this has to be a separate config
(short version: `terraform/proxmox/main.tf` reads both Proxmox and AWS
credentials from Vault, and terraform configures every declared provider
eagerly even under `-target`, so that config genuinely cannot run before
Vault exists).

## 1. Apply

Install Proxmox on the fresh/repaired hardware (Stage 0 in the DR doc).
Create an API token: Datacenter → Permissions → API Tokens. Note the root
SSH password set during install.

```bash
cd terraform/proxmox-bootstrap
terraform init
terraform apply \
  -var "proxmox_api_token_id=root@pam!bootstrap" \
  -var "proxmox_api_token_secret=<from the UI>" \
  -var "proxmox_ssh_password=<root password set during install>"
```

This creates 4 VM shells: `vault`, `pi-hole`, `service`, `opnsense`. Same
vm_id/spec/static IP as the normal config, so nothing downstream needs to
know these came from a different terraform run.

## 2. Bring each one up (Stage 2 in the DR doc)

- **OPNsense**: manual ISO install via Proxmox's console, then
  `restore_opnsense_config.py` to restore the firewall/DNS config.
- **Vault**: ansible install, then manual init/unseal, then
  `restore_vault_secrets.py` to restore the 46 KV secrets from the GitHub
  backup.
- **pi-hole**: ansible install (`configure_pi-hole.yml`) — fully unattended,
  nothing bootstrap-specific here.
- **service**: clone both repos, ansible installs Semaphore/Prometheus/the
  rest of the ops stack.

Once Vault is unsealed and has its real secrets back, every other host in
the fleet goes through the *normal* Vault-backed path again — this
config's job is done.

## 3. Reconcile state (do this before ever touching `terraform/proxmox` again)

This config's state doesn't know about `terraform/proxmox`'s state, and
vice versa — left alone, the next normal `terraform apply` would try to
create these 4 VMs a second time (vm_id collision) or, worse, someone runs
`rebuild_fleet.sh` and it has no idea these are the critical tier since
they're not in its state at all. Import them into the real state so it
matches reality, then abandon this one:

Note the resource names below are `terraform/proxmox`'s (the real config's)
addresses, not this directory's — `vms["pi-hole"]`/`vms["vault"]`, not
`critical_tier_vms[...]`. The two configs deliberately use different
resource names so they can never collide on the same address by accident.

```bash
cd terraform  # the root module, not proxmox-bootstrap
terraform import 'module.proxmox_resources.proxmox_virtual_environment_vm.opnsense' <node>/101
terraform import 'module.proxmox_resources.proxmox_virtual_environment_vm.vms["pi-hole"]' <node>/102
terraform import 'module.proxmox_resources.proxmox_virtual_environment_vm.service' <node>/103
terraform import 'module.proxmox_resources.proxmox_virtual_environment_vm.vms["vault"]' <node>/104
```

After importing, run `terraform plan` against the root module — it should
come back clean (or only show cosmetic diffs, same as any other import).
Do **not** run `terraform destroy` or `terraform apply` from
`proxmox-bootstrap/` again after this point; delete its
`terraform.tfstate` once the plan above is clean, so nothing ever targets
these VMs from two states at once.
