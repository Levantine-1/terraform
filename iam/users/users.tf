# Define IAM users

variable "users" {
  type    = list(string)
  default = ["terraform_admin",
             "terraform_thisper",
             "terraform_theia",
             "terraform_portfolio",
             "terraform_datagateway",
             "terraform_processmining",
             "terraform_pet-care",
             "terraform_dental-care",
             "terraform_education-platform",
             "terraform_real-estate",
             "terraform_booking-movie-ticket"
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
# NOTE: 2026-07-26 commented out during state reconciliation. AWS never
# returns an access key's secret after creation, so `each.value.secret` is
# only non-null when terraform creates the key in the very same apply that
# creates this resource. For every currently-existing access key (imported
# into state, not created by this apply), secret is permanently null --
# leaving this resource active makes every `terraform plan` fail (or, if
# someone forced past that, would try to overwrite the real working Vault
# secrets with null/empty data on apply). The real secrets are already
# correct in Vault from original creation; nothing needs this resource to
# run right now. Re-enable it (with a null-guard, e.g. `try()`, and ideally
# a way to distinguish "just-created" from "pre-existing" keys) before it's
# needed again, e.g. for a genuinely fresh IAM user creation.
#
# resource "vault_generic_secret" "store_access_keys_in_vault" {
#   for_each = aws_iam_access_key.create_access_keys
#
#   path = "kv/aws/iam_access_keys/${each.value.user}"  # Use a specific path for each access key
#   data_json = <<EOT
# {
#   "access_key": "${each.value.id}",
#   "secret_key": "${each.value.secret}"
# }
# EOT
# }

# Store access keys for the 5 microservice users added alongside portfolio/
# thisper/processmining (see supported_containers in the ansible repo's
# group_vars/VMWareDockerHosts). These are genuinely fresh creates in this
# apply, so -- unlike the six pre-existing users above -- each.value.secret
# is guaranteed non-null here. Filtered by name rather than reusing the
# commented-out resource above so this never touches the pre-existing
# users' already-correct Vault secrets.
locals {
  new_service_users = [
    "terraform_pet-care",
    "terraform_dental-care",
    "terraform_education-platform",
    "terraform_real-estate",
    "terraform_booking-movie-ticket",
  ]
}

resource "vault_generic_secret" "store_new_service_access_keys" {
  for_each = {
    for idx, key in aws_iam_access_key.create_access_keys :
    aws_iam_user.create_users[idx].name => key
    if contains(local.new_service_users, aws_iam_user.create_users[idx].name)
  }

  path = "kv/aws/iam_access_keys/${each.key}"
  data_json = <<EOT
{
  "access_key": "${each.value.id}",
  "secret_key": "${each.value.secret}"
}
EOT
}
