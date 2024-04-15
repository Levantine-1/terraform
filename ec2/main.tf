# Load IAM resources from separate files
variable "environment" {}

# Add a default key for ansible to bootstrap later
resource "aws_key_pair" "automation_key_pair" {
  key_name   = "automation"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlK9SYgHttisI9NMozvE0HNroEK2bBG406szUfIGz1Xq+CGTdW1x197nBh36zqa5gYbhQCM/uGKOaGCPB+6R6gW0CpaHjPvcKW+pKAUaEWkQzeRYaS1yEJjD4Fh+DFqgaYKh+VTCH7RC2c6N+YdKKJkaSan2iaI9Z5nLjAxJloepbJBTDnhPQVasqNUykh6ZbYyYM5p3EEhYPrw5bMZJJkyHV44UexfqBmroSgbA87PtyUw/+9T9aG3yYwtAafUZJlZpWbeHdMRW/SVYmt/wCze5x+IAxqjk+48b8HeltR5Nys33VSQybuKNrcnumDNzthLFMQvF4ABO66yCTQ5NaBQ== automation"
}

module "aws_security_groups" {
  source = "./security_groups"
}

module "aws_ec2" {
  depends_on = [module.aws_security_groups]
  source = "./instances"
  environment = var.environment
}