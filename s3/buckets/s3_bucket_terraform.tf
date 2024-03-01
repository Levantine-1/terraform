variable "environment" {}

# I'm using environment variable from tfvars
# to create a unique bucket name as it needs to be globally unique
resource "aws_s3_bucket" "s3_bucket_terraform" {
  bucket = "${var.environment}-levantine-terraform"
}

resource "aws_s3_bucket_versioning" "s3_bucket_terraform_versioning" {
  bucket = aws_s3_bucket.s3_bucket_terraform.id
  versioning_configuration {
    status = "Enabled"
  }
}