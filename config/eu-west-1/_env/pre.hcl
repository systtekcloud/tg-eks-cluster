#------------------------------------------------------------------------------
# Pre (Staging) Environment Configuration - Module-level settings only
# Identity (region, account, env name) → region.hcl / env.hcl / account.hcl
#------------------------------------------------------------------------------
locals {
  #----------------------------------------------------------------------------
  # Module Versions
  #----------------------------------------------------------------------------
  vpc_module_version = "vpc-v0.1.0"

  #----------------------------------------------------------------------------
  # VPC Configuration - Pre mirrors prod structure, dev costs
  #----------------------------------------------------------------------------
  vpc_config = {
    cidr               = "10.1.0.0/16"  # Different CIDR for VPC peering
    availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

    public_subnet_cidrs  = ["10.1.0.0/19", "10.1.32.0/19", "10.1.64.0/19"]
    private_subnet_cidrs = ["10.1.96.0/19", "10.1.128.0/19", "10.1.160.0/19"]

    # Still cost-optimized but 3 AZs like prod
    enable_nat_gateway = true
    single_nat_gateway = true

    # Isolated subnets for database testing
    create_isolated_subnets = true
    isolated_subnet_cidrs   = ["10.1.192.0/20", "10.1.208.0/20", "10.1.224.0/20"]
  }

  #----------------------------------------------------------------------------
  # Feature Flags
  #----------------------------------------------------------------------------
  features = {
    vpc_flow_logs    = true
    vpc_endpoints    = true
    eks              = false
    alb              = false
    monitoring       = false
  }

  #----------------------------------------------------------------------------
  # Flow Logs Configuration (Phase 2)
  #----------------------------------------------------------------------------
  flow_logs_config = {
    enable             = true
    traffic_type       = "ALL"
    retention_days     = 30
    enable_access_logs = false
  }

  #----------------------------------------------------------------------------
  # VPC Endpoints Configuration (Phase 3)
  #----------------------------------------------------------------------------
  vpc_endpoints_config = {
    gateway_endpoints   = ["s3", "dynamodb"]
    interface_endpoints = ["ecr.api", "ecr.dkr", "secretsmanager", "sts"]
    shared_sg           = true
  }

  #----------------------------------------------------------------------------
  # EKS Configuration
  #----------------------------------------------------------------------------
  eks_config = {
    cluster_name    = "pre-platform"
    cluster_version = "1.34"

    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"          = "1"
      "kubernetes.io/cluster/pre-platform"       = "owned"
    }
    public_subnet_tags = {
      "kubernetes.io/role/elb"                   = "1"
      "kubernetes.io/cluster/pre-platform"       = "owned"
    }
  }
}
