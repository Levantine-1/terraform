# Load IAM resources from separate files
variable "region" {}

# Manage IAM users
module "iam_users" {
  source = "./users"
}

# Manage IAM groups
module "iam_groups" {
  source = "./groups"
}

data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
}

# Manage IAM policies
module "iam_policies" {
  source = "./policies"
  region = var.region
  aws_account_id = local.account_id
}

# Note, due to some kind of race condition group associations may not be created or destroyed properly
# you may have to run this multiple times for the users and groups to be created or destroyed.
# I've tried adding sleeps but that didn't really work.


# Associate users with groups
module "group_memberships" {
  source = "./group_memberships"
}