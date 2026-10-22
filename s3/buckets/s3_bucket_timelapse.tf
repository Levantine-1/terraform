# Off-site copy of the timelapse frames captured on `service` (ansible
# roles/applications/timelapse). One plain .tar per camera per UTC day, in
# DEEP_ARCHIVE: the frames are irreplaceable and live on a single SSD at
# home, but this copy is only ever read back if that disk dies, so the
# cheapest, slowest-to-restore class is the right one.
resource "aws_s3_bucket" "s3_bucket_timelapse" {
  bucket = "${var.environment}-levantine-timelapse-archive"
}

# Versioning plus a writer that cannot delete (see
# iam/policies/timelapse_backup_policy.tf): an overwrite of an existing day
# keeps the earlier version rather than losing it.
resource "aws_s3_bucket_versioning" "s3_bucket_timelapse_versioning" {
  bucket = aws_s3_bucket.s3_bucket_timelapse.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_timelapse_public_access" {
  bucket                  = aws_s3_bucket.s3_bucket_timelapse.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_timelapse_encryption" {
  bucket = aws_s3_bucket.s3_bucket_timelapse.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
