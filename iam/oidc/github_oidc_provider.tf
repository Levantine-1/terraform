# Account-wide GitHub Actions OIDC provider. Created exactly once here --
# every child repo's own terraform (portfolio, thisper, etc.) references
# this via a data source rather than creating its own; a second
# aws_iam_openid_connect_provider for the same issuer URL would collide.
#
# Lets GitHub Actions workflows assume an AWS IAM role via short-lived
# federated tokens (aws-actions/configure-aws-credentials + role-to-assume)
# instead of long-lived static IAM user keys stored in Vault -- the CI/CD
# migration this is part of moves each child repo's own `terraform apply`
# onto this instead of the terraform_<name> Vault-key pattern still used
# elsewhere (e.g. by ansible pulling images from ECR, which is a separate,
# unrelated identity/purpose).
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # AWS verifies the actual chain server-side for well-known CAs regardless
  # of what's listed here, but the provider still requires a value. This is
  # the live root CA thumbprint (ISRG Root X1 -- GitHub's OIDC endpoint is
  # Let's Encrypt-backed), computed directly against
  # token.actions.githubusercontent.com rather than copied from memory, to
  # avoid a transcription error in a 40-char hex string.
  thumbprint_list = [
    "ab9d0263244dd0326eb67015705a667e79cfe998",
  ]
}

output "github_actions_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
