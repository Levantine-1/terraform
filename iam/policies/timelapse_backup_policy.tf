# Write-only access to the timelapse archive bucket, for the nightly backup
# job on `service` (ansible roles/applications/timelapse).
#
# Deliberately no s3:DeleteObject and no GetObject: the job only ever adds
# a day's .tar, so a compromised `service` can neither wipe nor read the
# archive. Restores are done with admin credentials, by hand.
#
# PutObject is conditioned on DEEP_ARCHIVE so nothing can accidentally land
# in a pricier class. That condition is also why the backup uploads with a
# single PutObject rather than multipart: UploadPart requests carry no
# storage-class header, so they would fail the condition. A day's .tar is
# far below the 5 GB single-PUT limit.

resource "aws_iam_policy" "timelapse_backup_policy" {
  name        = "timelapse_backup_policy"
  description = "Write-only DEEP_ARCHIVE uploads to the timelapse archive bucket"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:PutObject"],
            "Resource": "arn:aws:s3:::prod-levantine-timelapse-archive/*",
            "Condition": {
                "StringEquals": {"s3:x-amz-storage-class": "DEEP_ARCHIVE"}
            }
        },
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": "arn:aws:s3:::prod-levantine-timelapse-archive"
        }
    ]
}
EOF
}

variable "groups_in_timelapse_backup_policy" {
  description = "List of groups to attach this policy to."
  type        = list(string)
  default     = ["timelapse_backup_group"]
}

resource "aws_iam_group_policy_attachment" "timelapse_backup_policy_group_attachment" {
  for_each = { for group in var.groups_in_timelapse_backup_policy : group => group }
    group      = each.value
    policy_arn = aws_iam_policy.timelapse_backup_policy.arn
}
