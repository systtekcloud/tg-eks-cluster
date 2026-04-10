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
    cluster_version = "1.35"

    # Subnet tags (also consumed by vpc/terragrunt.hcl)
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"        = "1"
      "kubernetes.io/cluster/pre-platform"     = "owned"
    }
    public_subnet_tags = {
      "kubernetes.io/role/elb"                 = "1"
      "kubernetes.io/cluster/pre-platform"     = "owned"
    }

    endpoint_private_access = true
    endpoint_public_access  = false
    public_access_cidrs     = []

    authentication_mode             = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin = true

    cluster_log_types          = ["api", "audit"]
    cluster_log_retention_days = 14

    enable_cluster_encryption = false

    node_groups = {
      system = {
        instance_types = ["t3.medium"]
        desired_size   = 2
        min_size       = 2
        max_size       = 4
        capacity_type  = "ON_DEMAND"
        labels = {
          role = "system"
        }
        taints = []
      }
    }

    addons = {
      coredns                = { version = "v1.11.4-eksbuild.2" }
      kube-proxy             = { version = "v1.35.0-eksbuild.1" }
      vpc-cni                = { version = "v1.19.2-eksbuild.1" }
      aws-ebs-csi-driver     = { version = "v1.37.0-eksbuild.1" }
      snapshot-controller    = { version = "v8.2.0-eksbuild.1" }
      eks-pod-identity-agent = { version = "v1.3.4-eksbuild.1" }
    }
  }
}
