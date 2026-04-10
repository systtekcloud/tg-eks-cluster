#------------------------------------------------------------------------------
# EKS Module - Dev Environment
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
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../infra//eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock-12345"
    vpc_cidr_block     = "10.0.0.0/16"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  # Cluster config
  cluster_name    = include.env.locals.eks_config.cluster_name
  cluster_version = include.env.locals.eks_config.cluster_version

  # Network
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr_block
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # Endpoint access
  endpoint_private_access = include.env.locals.eks_config.endpoint_private_access
  endpoint_public_access  = include.env.locals.eks_config.endpoint_public_access
  public_access_cidrs     = include.env.locals.eks_config.public_access_cidrs

  # Authentication
  authentication_mode             = include.env.locals.eks_config.authentication_mode
  bootstrap_cluster_creator_admin = include.env.locals.eks_config.bootstrap_cluster_creator_admin

  # Logging
  cluster_log_types          = include.env.locals.eks_config.cluster_log_types
  cluster_log_retention_days = include.env.locals.eks_config.cluster_log_retention_days

  # Encryption
  enable_cluster_encryption = include.env.locals.eks_config.enable_cluster_encryption

  # Node groups
  node_groups = include.env.locals.eks_config.node_groups

  # Addons
  addons = include.env.locals.eks_config.addons

  # Common
  environment  = include.common.locals.environment
  project_name = include.common.locals.project_name
  tags         = include.common.locals.default_tags
}
