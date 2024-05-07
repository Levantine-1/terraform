# Terraform Configuration for Levantine-1

This repository contains the Terraform configuration files for setting up various AWS resources. The configuration is modularized into separate directories for each type of resource, including IAM, S3, Route53, and EC2.

## Configuration Overview

The main configuration file is `main.tf`, which sets up the necessary providers and data sources, and calls the various modules to set up the resources.

The AWS credentials are retrieved from a Vault server, the address and token for which are passed in as variables. If the credentials are not available in Vault, the module will fail.

The modules are set up in the following order:

1. IAM resources (`./iam`)
2. S3 resources (`./s3`)
3. Route53 resources (`./route53`)
4. EC2 resources (`./ec2`)

## Execution

Although the original intention was to build the stack in chunks, for operational simplicity, the entire stack is built by executing the root `main.tf` file.

This Terraform configuration is executed by a Jenkins job. The job pulls this repository, runs the Terraform scripts from the root main.tf, and backs up the state file to an S3 bucket.
I'm well aware that Terraform supports a S3 backend, and I have a ticket out for that: https://levantine2.atlassian.net/browse/DEVOPS-69 
But for now executing on Jenkins and shipping the state file to S3 still meets my minimum requirements.

To execute the configuration, stay in the project root directory and execute the root `main.tf` file with the appropriate environment variables file:

```bash
terraform apply --var_file=./vars/<environment>.tfvars
```

## Notes:
The AWS Delegate provider is purely just for creating route 53 records in the root AWS account. The AWS provider is used for all other resources.
It only has route 53 permissions anyways.

The EC2 module will fail when running for the first time because the security group wouldn't be available by the time terraform launches the EC2 since the security group is created in a different module. I couldn't make it dependent on the security groups creation step due to some weird deprecation issue with route53 and I couldn't figure it out. So if this env is spun up for the first time, the EC2 module will need to be commented out, then re-enabled once the stack run the first time.
I suppose in an ideal scenario the bastion host would be created in a separate module and we'd run the terraform apply on it separately.