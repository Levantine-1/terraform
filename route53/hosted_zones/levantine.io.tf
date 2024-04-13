variable "levantine_io_hosted_zone_id" {}

# Create new hosted zone for TLD delegation
resource "aws_route53_zone" "levantine_io" {
  name = "${var.environment}.levantine.io"
}

# This configures the subdomain delegation on the account that owns the TLD
resource "aws_route53_record" "configure_subdomain_delegation" {
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

# Only create this Address Record in the prod environment
resource "aws_route53_record" "create_prod_redirect_record" {
  provider = aws.delegate
  count   = var.environment == "prod" ? 1 : 0
  name    = "levantine.io"
  zone_id = var.levantine_io_hosted_zone_id
  type    = "A"
  ttl     = 300
  records = [data.aws_eip.bastion_eip.public_ip]
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