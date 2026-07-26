# Define IAM groups
variable "groups" {
  default = [
    "terraform_admin_group",
    "terraform_thisper_group",
    "terraform_theia_group",
    "terraform_portfolio_group",
    "terraform_datagateway_group",
    "terraform_processmining_group"
  ]
}

resource "aws_iam_group" "groups" {
  for_each = { for idx, group in var.groups : idx => group }
  name     = each.value
}
