variable "levantine_io_hosted_zone_id" {}

# Create new hosted zone for TLD delegation
resource "aws_route53_zone" "levantine_io" {
  name = "${var.environment}.levantine.io"
}

# This configures the subdomain delegation on the account that owns the TLD
resource "aws_route53_record" "configure_subdomain_delegation_levantine_io" {
  provider = aws.delegate
  allow_overwrite = true
  name            = "${var.environment}.levantine.io"
  ttl             = 300
  type            = "NS"
  zone_id         = var.levantine_io_hosted_zone_id

  records = [
    aws_route53_zone.levantine_io.name_servers[0],
    aws_route53_zone.levantine_io.name_servers[1],
    aws_route53_zone.levantine_io.name_servers[2],
    aws_route53_zone.levantine_io.name_servers[3],
  ]
}

#################### ALL RECORDS BELOW SHOULD BE IN THE ACCOUNT THAT HOSTS THIS ENVIRONMENT ####################

## This record is now defined in the file that creates the instance
# resource "aws_route53_record" "configure_bastion_r53_record" {
#   zone_id = aws_route53_zone.levantine_io.zone_id
#   name    = "prod.levantine.io"
#   type    = "A"
#   ttl     = 300
#   records = ["54.187.93.242"]
# }

resource "aws_route53_record" "vmwarebastion_vpn_levantine_io" {
  zone_id = aws_route53_zone.levantine_io.zone_id
  name = "vmwarebastion.vpn.${var.environment}.levantine.io"
  type = "A"
  ttl = 300
  records = ["10.0.0.3"]
}

# This record is for the legacy "theia" project. Theia will not be receiving the CICD treatment so for now this is manually in here
resource "aws_route53_record" "configure_theia_r53_levantine_record" {
  provider = aws.delegate
  zone_id = var.levantine_io_hosted_zone_id
  name    = "theia.levantine.io"
  type    = "A"
  ttl     = 300
  records = ["54.70.96.91"]
}

# service's ops dashboard, reachable at its LAN IP -- same pattern as
# create_splunk_vpn_record (ec2/instances/bastion.tf): a public DNS name
# resolving to a 192.168.1.x address, never intended to be reachable from
# outside the house. Gives it a real hostname for a proper TLS cert
# (roles/os_configs/deploySSLCerts.yml's *.levantine.io wildcard already
# covers it) instead of a bare-IP plain-HTTP page.
#
# This record alone is not enough to resolve from inside the house. OPNsense's
# Unbound already has two host overrides under bare levantine.io (livecam,
# livecam-lan -- see roles/applications/opnsense/backups/config.xml), which
# makes levantine.io a local zone there. Confirmed live (2026-08-23):
# local_zone_type is "transparent", which per Unbound's own semantics should
# fall through to real recursion for any name not explicitly listed -- but
# empirically service.levantine.io returned NOERROR/NODATA from OPNsense's
# resolver even though the real Route53 record resolved correctly and
# immediately via a public resolver (8.8.8.8), and waiting out a plausible
# negative-cache TTL didn't fix it either. The reliable fix -- proven by
# livecam-lan already working the same way -- is an explicit Unbound host
# override for the new name too
# (roles/applications/opnsense/files/add_dns_host_override.py <name> <ip>
# --domain levantine.io), not just the Route53 record. Any future bare
# *.levantine.io record needs that same second step, or it resolves fine
# from outside the house and nowhere inside it.
resource "aws_route53_record" "service_levantine_io" {
  provider = aws.delegate
  count    = var.environment == "prod" ? 1 : 0
  zone_id  = var.levantine_io_hosted_zone_id
  name     = "service.levantine.io"
  type     = "A"
  ttl      = 300
  # Home-LAN address (net0/eth0, 10.69.69.0/24), not the internal VLAN
  # address (192.168.1.50) -- reachable directly from devices on the home LAN
  # without a hop through OPNsense. Confirmed live (2026-08-23): this is a
  # floating DHCP lease (no static reservation for eth0's MAC,
  # bc:24:11:52:91:25, in OPNsense's DHCP config), so it can change on a
  # reboot or lease renewal -- add one if this address needs to stay durable.
  records = ["10.69.69.133"]
}