# Load IAM resources from separate files
variable "region" {}
variable "access_key" {}
variable "secret_key" {}
variable "environment" {}

provider "aws" {
  # These variables accessed via tfvar files in the root directory
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Manage s3 buckets
module "s3_buckets" {
  source = "./buckets"
  environment = var.environment
}