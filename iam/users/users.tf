# Define IAM users

variable "users" {
  type    = list(string)
  default = ["terraform_admin",
             "terraform_thisper",
             "terraform_theia",
             "terraform_booking-movie-ticket",
             "terraform_real-estate",
             "terraform_portfolio",
             "terraform_dental-care",
             "terraform_education-platform"
    ]
}

# Create IAM Users and Access Keys
resource "aws_iam_user" "create_users" {
  for_each = { for idx, user in var.users : idx => user }
  name     = each.value
}

resource "aws_iam_access_key" "create_access_keys" {
  for_each = aws_iam_user.create_users
  user     = each.value.name
}

# Store IAM access keys into Vault
resource "vault_generic_secret" "store_access_keys_in_vault" {
  for_each = aws_iam_access_key.create_access_keys

  path = "kv/aws/iam_access_keys/${each.value.user}"  # Use a specific path for each access key
  data_json = <<EOT
{
  "access_key": "${each.value.id}",
  "secret_key": "${each.value.secret}"
}
EOT
}
