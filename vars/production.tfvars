environment = "prod"

# AWS Configs
region = "us-west-2"

# HashiCorp Vault Configs
vault_address = "http://vault.internal.levantine.io:8200"
# NOTE: The vault token is currently added manually to the config file. This will be replaced with a more secure method in the future.
vault_token = "<token>"

# Route53 Configs
# The below hosted zone IDs came from the root account
levantine_io_hosted_zone_id = "<ZONE_ID>"
nhitruong_com_hosted_zone_id = "<ZONE_ID>"