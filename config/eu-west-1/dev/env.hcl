#------------------------------------------------------------------------------
# Dev Environment Local Variables
# This file is included by each component in the dev environment
#------------------------------------------------------------------------------
locals {
  env = basename(get_terragrunt_dir())
}
