#------------------------------------------------------------------------------
# VPC Module - Pre Environment
#------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/common.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

include "env" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/${basename(dirname(get_terragrunt_dir()))}.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../infra//vpc"
}

inputs = {
  vpc_cidr           = include.env.locals.vpc_config.cidr
  availability_zones = include.env.locals.vpc_config.availability_zones

  public_subnet_cidrs  = include.env.locals.vpc_config.public_subnet_cidrs
  private_subnet_cidrs = include.env.locals.vpc_config.private_subnet_cidrs

  enable_nat_gateway = include.env.locals.vpc_config.enable_nat_gateway
  single_nat_gateway = include.env.locals.vpc_config.single_nat_gateway

  create_isolated_subnets = include.env.locals.vpc_config.create_isolated_subnets
  isolated_subnet_cidrs   = include.env.locals.vpc_config.isolated_subnet_cidrs

  private_subnet_tags = include.env.locals.eks_config.private_subnet_tags
  public_subnet_tags  = include.env.locals.eks_config.public_subnet_tags
}
