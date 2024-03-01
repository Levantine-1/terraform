variable "user_group_associations" {
  description = "Map of user names to a list of group names."
  type        = map(list(string))
  default     = {
    terraform_admin       = ["terraform_admin_group"],
    terraform_thisper     = ["terraform_thisper_group"],
    terraform_thiea       = ["terraform_thiea_group"],
    terraform_bmt         = ["terraform_bmt_group"],
    terraform_real-estate = ["terraform_real-estate_group"]
    # Add more user-group associations as needed
  }
}

resource "aws_iam_user_group_membership" "user_group_membership" {
  for_each = var.user_group_associations

  user  = each.key
  groups = each.value
}