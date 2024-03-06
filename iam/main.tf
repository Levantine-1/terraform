# Load IAM resources from separate files
variable "region" {}
variable "access_key" {}
variable "secret_key" {}
variable "vault_address" {}
variable "vault_token" {}
variable "aws_account_id" {}

provider "aws" {
  # These variables accessed via tfvar files in the root directory
  region = var.region
   access_key = var.access_key
   secret_key = var.secret_key
}

# Manage IAM users
module "iam_users" {
  source = "./users"
  vault_address = var.vault_address
  vault_token = var.vault_token
}

# Manage IAM groups
module "iam_groups" {
  source = "./groups"
}

# Manage IAM policies
module "iam_policies" {
  source = "./policies"
  aws_account_id = var.aws_account_id
  region = var.region
}

# Note, due to some kind of race condition group associations may not be created or destroyed properly
# you may have to run this multiple times for the users and groups to be created or destroyed.
# I've tried adding sleeps but that didn't really work.


# Associate users with groups
module "group_memberships" {
  source = "./group_memberships"
}