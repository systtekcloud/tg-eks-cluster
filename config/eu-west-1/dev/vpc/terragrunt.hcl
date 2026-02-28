#------------------------------------------------------------------------------
# VPC Module - Dev Environment
#------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Common variables: aws_region, aws_account_id, environment, project_name, default_tags
include "common" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/common.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

# Env-specific config: vpc_config, features, eks_config, module versions
# Path uses basename(dirname(get_terragrunt_dir())) → "dev" (no local.* reference)
include "env" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/${basename(dirname(get_terragrunt_dir()))}.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  # Local path: dirname(root.hcl)/ .. → lab01-eks-cluster/
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../infra//vpc"

  # Git reference (for production):
  # source = "git::git@github.com:YOUR_ORG/infra.git//vpc?ref=${include.env.locals.vpc_module_version}"
}

inputs = {
  vpc_cidr           = include.env.locals.vpc_config.cidr
  availability_zones = include.env.locals.vpc_config.availability_zones

  public_subnet_cidrs  = include.env.locals.vpc_config.public_subnet_cidrs
  private_subnet_cidrs = include.env.locals.vpc_config.private_subnet_cidrs

  # Cost optimized for dev: single NAT
  enable_nat_gateway = include.env.locals.vpc_config.enable_nat_gateway
  single_nat_gateway = include.env.locals.vpc_config.single_nat_gateway

  create_isolated_subnets = include.env.locals.vpc_config.create_isolated_subnets
  isolated_subnet_cidrs   = include.env.locals.vpc_config.isolated_subnet_cidrs

  # Subnet tags for future EKS integration
  private_subnet_tags = include.env.locals.eks_config.private_subnet_tags
  public_subnet_tags  = include.env.locals.eks_config.public_subnet_tags
}
