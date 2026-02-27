#------------------------------------------------------------------------------
# Root Terragrunt Configuration
#
# This file is the main entry point for all Terragrunt configurations.
# It defines:
# - Remote state configuration (S3 + DynamoDB)
# - Provider generation
# - Common inputs
#
# Expected path structure: {region}/{env}/{component}
# Example: eu-west-1/dev/vpc
#
# Identity is resolved from dedicated files found via find_in_parent_folders:
#   region.hcl   → aws_region (derived from region folder name)
#   env.hcl      → env        (derived from env folder name)
#   account.hcl  → aws_account_id, project_name (explicit per env)
#------------------------------------------------------------------------------

locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  aws_region   = local.region_vars.locals.aws_region
  environment  = local.env_vars.locals.env
  account_id   = local.account_vars.locals.aws_account_id
  project_name = local.account_vars.locals.project_name
}

#------------------------------------------------------------------------------
# Remote State Configuration
#------------------------------------------------------------------------------
remote_state {
  backend = "s3"

  config = {
    # Each account has its own state bucket for isolation
    bucket         = "${local.project_name}-tfstate-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    use_lockfile   = true

    profile    = "devops"

    # Backend operations use tfadmin role in target account
    assume_role = {
      role_arn     = "arn:aws:iam::${local.account_id}:role/tfadmin"
      session_name = "terragrunt-backend-${local.environment}"
    }
  }

  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

#------------------------------------------------------------------------------
# Provider Configuration
#------------------------------------------------------------------------------
generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "aws" {
      region  = "${local.aws_region}"
      profile = "devops"

      assume_role {
        role_arn     = "arn:aws:iam::${local.account_id}:role/tfadmin"
        session_name = "terragrunt-${local.environment}"
      }

      default_tags {
        tags = {
          Environment = "${local.environment}"
          Project     = "${local.project_name}"
          ManagedBy   = "Terragrunt"
        }
      }
    }
  EOF
}

#------------------------------------------------------------------------------
# Common Inputs (available to all modules)
#------------------------------------------------------------------------------
inputs = {
  environment  = local.environment
  project_name = local.project_name
  aws_region   = local.aws_region

  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terragrunt"
  }
}
