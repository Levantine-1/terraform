variable "region" {}
variable "environment" {}
variable "vault_address" {}
variable "vault_token" {}
variable "levantine_io_hosted_zone_id" {}
variable "nhitruong_com_hosted_zone_id" {}

# NOTE: For some reason the IDE wants me to define the access keys for each of the modules.
# So for now I'll put them in there though I'd prefer they'd use the global ones.

# NOTE: The AWS credentials are not stored in vault here because these terraform templates are
# running outside of AWS. While I could do a STS-Assume Role, it's pointless since I'll need
# to provision and store credentials for the user/role that's doing the assuming. That being said,
# the keys generated when the users are created are stored and retrieved from vault.

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

data "vault_generic_secret" "aws_creds" {
  path = "kv/aws/iam_access_keys/terraform_admin"
}

provider "aws" {
  # This is the default account, don't specify an alias to use the default
  region = var.region
  # Secret and Access Keys from Vault
  # NOTE: If the keys are not available in vault, the values are gonna be 'null' and the module will fail
  # The keys could have been deleted by a destroy operation.
  access_key = try(data.vault_generic_secret.aws_creds.data["access_key"], null)
  secret_key = try(data.vault_generic_secret.aws_creds.data["secret_key"], null)
}

# Setup IAM resources
module "iam_resources" {
  source = "./iam"
  region = var.region
}

# Setup S3 resources
module "s3_resources" {
  depends_on = [module.iam_resources]
  source = "./s3"
  region = var.region
  environment = var.environment
}

# Setup Route53 resources
module "route53_resources" {
  source = "./route53"
  region = var.region
  environment = var.environment
  levantine_io_hosted_zone_id =  var.levantine_io_hosted_zone_id
  nhitruong_com_hosted_zone_id = var.nhitruong_com_hosted_zone_id
}

# Setup EC2 resources
module "ec2_resources" {
  depends_on = [module.iam_resources]
  source = "./ec2"
  environment = var.environment
}