variable "environment" {}
variable "nhitruong_com_hosted_zone_id" {}
variable "levantine_io_hosted_zone_id" {}

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

data "aws_route53_zone" "nhitruong_com_tld" {
  name = "${var.environment}.nhitruong.com"
}

################ Security Groups ################
# NOTE: The "name" values for these security groups are the name values
# defined for them in the templates under terraform/ec2/security_groups
variable "region" {}

data "aws_security_group" "ssh" {
  name = "ssh"
}

data "aws_security_group" "http_https" {
  name = "http_https"
}

data "aws_security_group" "wireguard" {
  name = "wireguard"
}

data "vault_generic_secret" "aws_delegation_creds" {
  path = "kv/aws/iam_access_keys/subdomain_delegation"
}

provider "aws" {
  # NOTE: The delegation account is used for DNS subdomain delegation between the root account and the subdomain account
  alias = "delegate"
  region = var.region
  access_key = try(data.vault_generic_secret.aws_delegation_creds.data["access_key"], null)
  secret_key = try(data.vault_generic_secret.aws_delegation_creds.data["secret_key"], null)
}