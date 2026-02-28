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
# Identity is resolved from:
#   path_relative_to_include() → region (path_parts[0]) + env (path_parts[1])
#   account.hcl                → aws_account_id, project_name (explicit per env)
#------------------------------------------------------------------------------

locals {
  path_parts   = split("/", path_relative_to_include())
  aws_region   = local.path_parts[0]  # eu-west-1
  environment  = local.path_parts[1]  # dev / pre / pro

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
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
    key            = "${local.aws_region}/${path_relative_to_include()}/terraform.tfstate"
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
