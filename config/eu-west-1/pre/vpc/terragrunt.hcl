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

  # Phase 2: Flow Logs
  enable_flow_logs             = include.env.locals.flow_logs_config.enable
  flow_logs_traffic_type       = include.env.locals.flow_logs_config.traffic_type
  flow_logs_retention_days     = include.env.locals.flow_logs_config.retention_days
  enable_flow_logs_access_logs = include.env.locals.flow_logs_config.enable_access_logs

  # Phase 3: VPC Endpoints
  gateway_endpoints   = include.env.locals.vpc_endpoints_config.gateway_endpoints
  interface_endpoints = include.env.locals.vpc_endpoints_config.interface_endpoints
  shared_endpoint_sg  = include.env.locals.vpc_endpoints_config.shared_sg
  aws_region          = include.common.locals.aws_region
}
