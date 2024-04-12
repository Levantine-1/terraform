variable "levantine_io_hosted_zone_id" {}

# Create new hosted zone for TLD delegation
resource "aws_route53_zone" "levantine_io" {
  name = "${var.environment}.levantine.io"
}

resource "aws_route53_record" "configure_subdomain_delegation" {
  provider = aws.delegate
  allow_overwrite = true
  name            = "${var.environment}.levantine.io"
  ttl             = 300
  type            = "NS"
  zone_id         = "${var.levantine_io_hosted_zone_id}"

  records = [
    aws_route53_zone.levantine_io.name_servers[0],
    aws_route53_zone.levantine_io.name_servers[1],
    aws_route53_zone.levantine_io.name_servers[2],
    aws_route53_zone.levantine_io.name_servers[3],
  ]
}