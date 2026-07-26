# Define IAM users

variable "users" {
  type    = list(string)
  default = ["terraform_admin",
             "terraform_thisper",
             "terraform_theia",
             "terraform_portfolio",
             "terraform_datagateway",
             "terraform_processmining"
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
# NOTE: AWS never returns an access key's secret after creation, so this only
# works when terraform itself creates the key in the same apply (secret is
# known from the create response). It can't be `terraform import`-ed for a
# pre-existing key -- each.value.secret comes back null and this resource
# has to be `terraform state rm`'d rather than imported during reconciliation,
# leaving the existing (correct) Vault secret alone rather than risk
# overwriting it with a null value. Fine again on a genuine fresh apply.
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
