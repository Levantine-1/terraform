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
