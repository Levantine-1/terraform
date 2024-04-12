# NOTE: Terraform does not allow string interpolation of resource names, so we have to hard code
# names here. This is not ideal, but it is the only way I could figure out how to do it.
# Just use find and replace tools to change the name of the policy, group, and attachment.

resource "aws_iam_policy" "terraform_admin_policy" {
  name        = "terraform_admin_policy"
  description = "Policy for terraform admin to bootstrap and manage basic AWS resources"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:AddUserToGroup",
                "iam:AttachGroupPolicy",
                "iam:AttachUserPolicy",
                "iam:CreateGroup",
                "iam:CreateLoginProfile",
                "iam:CreatePolicy",
                "iam:CreateUser",
                "iam:DeleteGroup",
                "iam:DeleteLoginProfile",
                "iam:DeletePolicy",
                "iam:DeleteUser",
                "iam:DetachGroupPolicy",
                "iam:DetachUserPolicy",
                "iam:GetGroup",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetUser",
                "iam:ListAttachedGroupPolicies",
                "iam:ListAttachedUserPolicies",
                "iam:ListGroups",
                "iam:ListGroupsForUser",
                "iam:ListPolicies",
                "iam:ListUsers",
                "iam:RemoveUserFromGroup",
                "iam:UpdateLoginProfile",
                "iam:ListPolicyVersions",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:CreateAccessKey",
                "iam:ListAccessKeys",
                "iam:DeleteAccessKey",
                "iam:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutBucketVersioning",
                "s3:DeleteBucket",
                "s3:DeleteBucketPolicy",
                "s3:PutBucketPolicy",
                "s3:GetBucketPolicy",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:ListBucketVersions",
                "s3:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

variable "groups_in_terraform_admin_policy" {
  description = "List of groups to attach this policy to."
  type        = list(string)
  default     = ["terraform_admin_group"] # Add more groups as needed, comma separated
}

resource "aws_iam_group_policy_attachment" "terraform_admin_policy_group_attachment" {
  for_each = { for group in var.groups_in_terraform_admin_policy : group => group }
    group      = each.value
    policy_arn = aws_iam_policy.terraform_admin_policy.arn
}