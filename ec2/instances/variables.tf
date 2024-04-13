variable "environment" {}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets"  {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

################ Route 53 Stuff ################
data "aws_route53_zone" "levantine_io_tld" {
  name = "${var.environment}.levantine.io"
}

################ Security Groups ################
# NOTE: The "name" values for these security groups are the name values
# defined for them in the templates under terraform/ec2/security_groups

data "aws_security_group" "ssh" {
  name = "ssh"
}

data "aws_security_group" "http_https" {
  name = "http_https"
}

data "aws_security_group" "wireguard" {
  name = "wireguard"
}