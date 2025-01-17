variable "nhitruong_com_hosted_zone_id" {}

# Create new hosted zone for TLD delegation
resource "aws_route53_zone" "nhitruong_com" {
  name = "${var.environment}.nhitruong.com"
}

# This configures the subdomain delegation on the account that owns the TLD
resource "aws_route53_record" "configure_subdomain_delegation_nhitruong_com" {
  provider = aws.delegate
  allow_overwrite = true
  name            = "${var.environment}.nhitruong.com"
  ttl             = 300
  type            = "NS"
  zone_id         = var.nhitruong_com_hosted_zone_id

  records = [
    aws_route53_zone.nhitruong_com.name_servers[0],
    aws_route53_zone.nhitruong_com.name_servers[1],
    aws_route53_zone.nhitruong_com.name_servers[2],
    aws_route53_zone.nhitruong_com.name_servers[3],
  ]
}

#################### ALL RECORDS BELOW SHOULD BE IN THE ACCOUNT THAT HOSTS THIS ENVIRONMENT ####################

## This record is now defined in the file that creates the instance
# resource "aws_route53_record" "configure_bastion_r53_record" {
#   zone_id = aws_route53_zone.nhitruong_com.zone_id
#   name    = "prod.nhitruong.com"
#   type    = "A"
#   ttl     = 300
#   records = ["54.187.93.242"]
# }

resource "aws_route53_record" "vmwarebastion_vpn_nhitruong_com" {
  zone_id = aws_route53_zone.nhitruong_com.zone_id
  name = "vmwarebastion.vpn.${var.environment}.nhitruong.com"
  type = "A"
  ttl = 300
  records = ["10.0.0.3"]
}

# This record is for the legacy "theia" project. Theia will not be receiving the CICD treatment so for now this is manually in here
resource "aws_route53_record" "configure_theia_r53_nhitruong_record" {
  provider = aws.delegate
  zone_id = var.nhitruong_com_hosted_zone_id
  name    = "theia.nhitruong.com"
  type    = "A"
  ttl     = 300
  records = ["54.70.96.91"]
}