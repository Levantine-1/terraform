variable "environment" {}
variable "region" {}

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