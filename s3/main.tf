# Load IAM resources from separate files
variable "region" {}
variable "environment" {}

# Manage s3 buckets
module "s3_buckets" {
  source = "./buckets"
  environment = var.environment
}