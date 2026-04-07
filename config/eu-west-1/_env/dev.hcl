#------------------------------------------------------------------------------
# Dev Environment Configuration - Module-level settings only
# Identity (region, account, env name) → region.hcl / env.hcl / account.hcl
#------------------------------------------------------------------------------
locals {
  #----------------------------------------------------------------------------
  # Module Versions (git tags from infra repo)
  #----------------------------------------------------------------------------
  vpc_module_version = "vpc-v0.1.0"
  # eks_module_version = "eks-v0.1.0"  # Uncomment when ready

  #----------------------------------------------------------------------------
  # VPC Configuration - Dev optimized for cost
  #----------------------------------------------------------------------------
  vpc_config = {
    cidr               = "10.0.0.0/16"
    availability_zones = ["eu-west-1a", "eu-west-1b"]

    # Subnet CIDRs - /19 gives 8190 IPs per subnet
    public_subnet_cidrs  = ["10.0.0.0/19", "10.0.32.0/19"]
    private_subnet_cidrs = ["10.0.64.0/19", "10.0.96.0/19"]

    # Cost optimization for dev
    enable_nat_gateway = true
    single_nat_gateway = true  # Single NAT saves ~$32/month

    # No isolated subnets in dev (databases in private subnets)
    create_isolated_subnets = false
    isolated_subnet_cidrs   = []
  }

  #----------------------------------------------------------------------------
  # Feature Flags - Control what gets deployed
  #----------------------------------------------------------------------------
  features = {
    vpc_flow_logs    = false
    vpc_endpoints    = false
    eks              = false
    alb              = false
    monitoring       = false
  }

  #----------------------------------------------------------------------------
  # Flow Logs Configuration (Phase 2)
  #----------------------------------------------------------------------------
  flow_logs_config = {
    enable             = false  # Disabled in dev for cost
    traffic_type       = "ALL"
    retention_days     = 7
    enable_access_logs = false
  }

  #----------------------------------------------------------------------------
  # VPC Endpoints Configuration (Phase 3)
  #----------------------------------------------------------------------------
  vpc_endpoints_config = {
    gateway_endpoints   = ["s3"]  # Free — always enable
    interface_endpoints = []      # None in dev for cost
    shared_sg           = true
  }

  #----------------------------------------------------------------------------
  # EKS Configuration (for when EKS is enabled)
  #----------------------------------------------------------------------------
  eks_config = {
    cluster_name    = "dev-platform"
    cluster_version = "1.34"

    # Tags required for EKS ALB controller
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/dev-platform"        = "owned"
    }
    public_subnet_tags = {
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/dev-platform"        = "owned"
    }
  }
}
