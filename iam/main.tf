# Load IAM resources from separate files
variable "region" {}

# Manage IAM users
module "iam_users" {
  source = "./users"
}

# Account-wide GitHub Actions OIDC provider -- created once here, child
# repos' own terraform reference it via a data source (see
# iam/oidc/github_oidc_provider.tf).
module "iam_oidc" {
  source = "./oidc"
}

# Manage IAM groups
module "iam_groups" {
  depends_on = [module.iam_users]
  source = "./groups"
}

data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
}

# Manage IAM policies
module "iam_policies" {
  depends_on = [module.iam_groups]
  source = "./policies"
  region = var.region
  aws_account_id = local.account_id
}

# Note, due to some kind of race condition group associations may not be created or destroyed properly
# you may have to run this multiple times for the users and groups to be created or destroyed.
# I've tried adding sleeps but that didn't really work.


# Associate users with groups
module "group_memberships" {
  depends_on = [module.iam_groups, module.iam_users]
  source = "./group_memberships"
}