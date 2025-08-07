# NOTE: Terraform does not allow string interpolation of resource names, so we have to hard code
# names here. This is not ideal, but it is the only way I could figure out how to do it.
# Just use find and replace tools to change the name of the policy, group, and attachment.

resource "aws_iam_policy" "terraform_processmining_policy" {
  name        = "terraform_processmining_policy"
  description = "Policy for terraform processmining to bootstrap and manage basic AWS resources"
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
                "ecr:GetDownloadUrlForLayer",
                "ecr:ListTagsForResource",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/processmining"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceCreditSpecifications"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:GetHostedZone",
                "route53:ListTagsForResource",
                "route53:ChangeResourceRecordSets",
                "route53:GetChange",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}

EOF
}

variable "groups_in_terraform_processmining_policy" {
  description = "List of groups to attach this policy to."
  type        = list(string)
  default     = ["terraform_processmining_group"] # Add more groups as needed, comma separated
}

resource "aws_iam_group_policy_attachment" "terraform_processmining_policy_group_attachment" {
  for_each = { for group in var.groups_in_terraform_processmining_policy : group => group }
    group      = each.value
    policy_arn = aws_iam_policy.terraform_processmining_policy.arn
}