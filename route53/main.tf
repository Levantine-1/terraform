# Load IAM resources from separate files
variable "region" {}
variable "environment" {}
variable "levantine_io_hosted_zone_id" {}

module "r53_hosted_zones" {
  source = "./hosted_zones"
  environment = var.environment
  levantine_io_hosted_zone_id = var.levantine_io_hosted_zone_id
  region = var.region
}