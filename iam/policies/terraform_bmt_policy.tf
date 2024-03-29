# NOTE: Terraform does not allow string interpolation of resource names, so we have to hard code
# names here. This is not ideal, but it is the only way I could figure out how to do it.
# Just use find and replace tools to change the name of the policy, group, and attachment.

resource "aws_iam_policy" "terraform_bmt_policy" {
  name        = "terraform_bmt_policy"
  description = "Policy for terraform bmt to bootstrap and manage basic AWS resources"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:DeleteRepository",
                "ecr:DescribeRepositories",
                "ecr:PutImage",
                "ecr:BatchDeleteImage",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:GetDownloadUrlForLayer"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/bmt"
        }
    ]
}

EOF
}

variable "groups_in_terraform_bmt_policy" {
  description = "List of groups to attach this policy to."
  type        = list(string)
  default     = ["terraform_bmt_group"] # Add more groups as needed, comma separated
}

resource "aws_iam_group_policy_attachment" "terraform_bmt_policy_group_attachment" {
  for_each = { for group in var.groups_in_terraform_bmt_policy : group => group }
    group      = each.value
    policy_arn = aws_iam_policy.terraform_bmt_policy.arn
}