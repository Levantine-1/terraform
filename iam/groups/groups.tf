# Define IAM groups
variable "groups" {
  default = [
    "terraform_admin_group",
    "terraform_thisper_group",
    "terraform_theia_group",
    "terraform_bmt_group",
    "terraform_real-estate_group",
    "terraform_portfolio"
  ]
}

resource "aws_iam_group" "groups" {
  for_each = { for idx, group in var.groups : idx => group }
  name     = each.value
}
