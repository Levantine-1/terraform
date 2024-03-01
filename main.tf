variable "region" {}
variable "access_key" {}
variable "secret_key" {}
variable "environment" {}

#provider "aws" {
#  # These variables accessed via tfvar files in the root directory
#   region = var.region
#   access_key = var.access_key
#   secret_key = var.secret_key
#}

# NOTE: For some reason the IDE wants me to define the access keys for each of the modules.
# So for now I'll put them in there though I'd prefer they'd use the global ones.

# Setup IAM resources
module "iam_resources" {
  source = "./iam"
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Setup S3 resources
module "s3_resources" {
  source = "./s3"
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  environment = var.environment
}