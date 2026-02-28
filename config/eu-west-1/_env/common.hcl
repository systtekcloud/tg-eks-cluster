#------------------------------------------------------------------------------
# Common Environment Variables
#
# Included by each component with expose = true, merge_strategy = "no_merge".
# All functions evaluate in the context of the CALLING terragrunt.hcl:
#   get_terragrunt_dir()      → caller's dir   (e.g. eu-west-1/dev/vpc/)
#   find_in_parent_folders()  → searches from caller's dir upward
#
# Access from components: include.common.locals.<var>
#------------------------------------------------------------------------------

locals {
  _region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  _account = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  aws_region     = local._region.locals.aws_region
  aws_account_id = local._account.locals.aws_account_id
  account_name   = local._account.locals.account_name
  project_name   = local._account.locals.project_name

  # Derived from directory structure: {region}/{env}/{component}
  environment = basename(dirname(get_terragrunt_dir()))

  default_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terragrunt"
  }
}
