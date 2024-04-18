# Load IAM resources from separate files
variable "environment" {}
variable "region" {}
variable "nhitruong_com_hosted_zone_id" {}
variable "levantine_io_hosted_zone_id" {}

# Add a default key for ansible to bootstrap later
resource "aws_key_pair" "automation_key_pair" {
  key_name   = "automation"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlK9SYgHttisI9NMozvE0HNroEK2bBG406szUfIGz1Xq+CGTdW1x197nBh36zqa5gYbhQCM/uGKOaGCPB+6R6gW0CpaHjPvcKW+pKAUaEWkQzeRYaS1yEJjD4Fh+DFqgaYKh+VTCH7RC2c6N+YdKKJkaSan2iaI9Z5nLjAxJloepbJBTDnhPQVasqNUykh6ZbYyYM5p3EEhYPrw5bMZJJkyHV44UexfqBmroSgbA87PtyUw/+9T9aG3yYwtAafUZJlZpWbeHdMRW/SVYmt/wCze5x+IAxqjk+48b8HeltR5Nys33VSQybuKNrcnumDNzthLFMQvF4ABO66yCTQ5NaBQ== automation"
}

module "aws_security_groups" {
  source = "./security_groups"
}

# 2024-04-17
# NOTE: Due to some jank in the variables.tf file, if you're running this for a new/empty env you'll need to:
# 1: Comment out the EC2 module
# 2: Run the terraform
# 3: Then uncomment the EC2 module
# 4: Run terraform again.
# This is because the hosted zone ids and security group IDs are not available until the first run.
# IDK, go easy on me ¯\_(ツ)_/¯  This is my first time using really Terraform

module "aws_ec2" {
  source = "./instances"
  environment = var.environment
  region = var.region
  nhitruong_com_hosted_zone_id = var.nhitruong_com_hosted_zone_id
  levantine_io_hosted_zone_id = var.levantine_io_hosted_zone_id
}