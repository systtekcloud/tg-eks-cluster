#------------------------------------------------------------------------------
# VPC Module - Dev Environment
#------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_name   = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
  env_config = read_terragrunt_config("${dirname(find_in_parent_folders("region.hcl"))}/_env/${local.env_name}.hcl")
}

#------------------------------------------------------------------------------
# Module Source
# 
# Options:
# - Local path (for development): "../../infra//vpc"
# - Git with tag (for production): "git::git@github.com:YOUR_ORG/infra.git//vpc?ref=${local.env_config.locals.vpc_module_version}"
#------------------------------------------------------------------------------
terraform {
  # Local path: root.hcl is at config/, so dirname(...)/ .. resolves to lab01-eks-cluster/
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../infra//vpc"

  # Git reference (for production):
  # source = "git::git@github.com:YOUR_ORG/infra.git//vpc?ref=${local.env_config.locals.vpc_module_version}"
}

#------------------------------------------------------------------------------
# Module Inputs
#------------------------------------------------------------------------------
inputs = {
  # VPC Core
  vpc_cidr           = local.env_config.locals.vpc_config.cidr
  availability_zones = local.env_config.locals.vpc_config.availability_zones

  # Subnets
  public_subnet_cidrs  = local.env_config.locals.vpc_config.public_subnet_cidrs
  private_subnet_cidrs = local.env_config.locals.vpc_config.private_subnet_cidrs

  # NAT Gateway (cost optimized for dev)
  enable_nat_gateway = local.env_config.locals.vpc_config.enable_nat_gateway
  single_nat_gateway = local.env_config.locals.vpc_config.single_nat_gateway

  # Isolated subnets (disabled for dev)
  create_isolated_subnets = local.env_config.locals.vpc_config.create_isolated_subnets
  isolated_subnet_cidrs   = local.env_config.locals.vpc_config.isolated_subnet_cidrs

  # Subnet tags for future EKS integration
  private_subnet_tags = local.env_config.locals.eks_config.private_subnet_tags
  public_subnet_tags  = local.env_config.locals.eks_config.public_subnet_tags
}
