variable "region" {}
variable "environment" {}
variable "vault_address" {}
variable "vault_token" {}
variable "aws_account_id" {}

# NOTE: For some reason the IDE wants me to define the access keys for each of the modules.
# So for now I'll put them in there though I'd prefer they'd use the global ones.

# NOTE: The AWS credentials are not stored in vault here because these terraform templates are
# running outside of AWS. While I could do a STS-Assume Role, it's pointless since I'll need
# to provision and store credentials for the user/role that's doing the assuming. That being said,
# the keys generated when the users are created are stored and retrieved from vault.


provider "aws" {
  region = var.region
  # Secret and Access Keys from Vault
}

provider "vault" {
  address = var.vault_address
  token = var.vault_token
}

data "vault_generic_secret" "aws_creds" {
  path = "secret/aws/iam_access_keys/terraform_admin"
}

variable "aws_access_key" {
  # default = "<access_key>" # NOTE: Use this if vault is unavailable. DO NOT USE FOR PRODUCTION!
  default = data.vault_generic_secret.aws_creds.data["access_key"]
}

variable "aws_secret_key" {
  # default = "<secret_key>" # NOTE: Use this if vault is unavailable. DO NOT USE FOR PRODUCTION!
  default = data.vault_generic_secret.aws_creds.data["secret_key"]
}

# Setup IAM resources
module "iam_resources" {
  source = "./iam"
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  vault_address = var.vault_address
  vault_token = var.vault_token
  aws_account_id = var.aws_account_id
}

# Setup S3 resources
module "s3_resources" {
  source = "./s3"
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  environment = var.environment
}