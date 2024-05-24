# Define IAM groups
variable "groups" {
  default = [
    "terraform_admin_group",
    "terraform_thisper_group",
    "terraform_theia_group",
    "terraform_booking-movie-ticket_group",
    "terraform_real-estate_group",
    "terraform_portfolio_group",
    "terraform_dental-care_group",
    "terraform_education-platform_group",
    "terraform_pet-care_group"
  ]
}

resource "aws_iam_group" "groups" {
  for_each = { for idx, group in var.groups : idx => group }
  name     = each.value
}
