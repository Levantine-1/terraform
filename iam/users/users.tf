# Define IAM users
variable "users" {
  default = [
    "terraform_admin",
    "terraform_thisper",
    "terraform_thiea",
    "terraform_bmt",
    "terraform_real-estate",
  ]
}

resource "aws_iam_user" "users" {
  for_each = { for idx, user in var.users : idx => user }
  name     = each.value
}
