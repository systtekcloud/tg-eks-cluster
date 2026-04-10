#------------------------------------------------------------------------------
# Pro (Production) Environment Configuration - Module-level settings only
# Identity (region, account, env name) → region.hcl / env.hcl / account.hcl
#------------------------------------------------------------------------------
locals {
  #----------------------------------------------------------------------------
  # Module Versions - Pin specific versions in prod
  #----------------------------------------------------------------------------
  vpc_module_version = "vpc-v0.1.0"

  #----------------------------------------------------------------------------
  # VPC Configuration - Production optimized for HA
  #----------------------------------------------------------------------------
  vpc_config = {
    cidr               = "10.2.0.0/16"
    availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

    public_subnet_cidrs  = ["10.2.0.0/19", "10.2.32.0/19", "10.2.64.0/19"]
    private_subnet_cidrs = ["10.2.96.0/19", "10.2.128.0/19", "10.2.160.0/19"]

    # HA configuration - NAT per AZ
    enable_nat_gateway = true
    single_nat_gateway = false  # One NAT per AZ for HA (~$96/month)

    # Isolated subnets for databases
    create_isolated_subnets = true
    isolated_subnet_cidrs   = ["10.2.192.0/20", "10.2.208.0/20", "10.2.224.0/20"]
  }

  #----------------------------------------------------------------------------
  # Feature Flags
  #----------------------------------------------------------------------------
  features = {
    vpc_flow_logs    = true
    vpc_endpoints    = true
    eks              = false
    alb              = false
    monitoring       = true
  }

  #----------------------------------------------------------------------------
  # Flow Logs Configuration (Phase 2)
  #----------------------------------------------------------------------------
  flow_logs_config = {
    enable             = true
    traffic_type       = "ALL"
    retention_days     = 90
    enable_access_logs = true  # Full audit trail in prod
  }

  #----------------------------------------------------------------------------
  # VPC Endpoints Configuration (Phase 3)
  #----------------------------------------------------------------------------
  vpc_endpoints_config = {
    gateway_endpoints   = ["s3", "dynamodb"]
    interface_endpoints = ["ecr.api", "ecr.dkr", "secretsmanager", "sts", "ssm", "logs"]
    shared_sg           = false  # Individual SGs in prod for compliance
  }

  #----------------------------------------------------------------------------
  # EKS Configuration
  #----------------------------------------------------------------------------
  eks_config = {
    cluster_name    = "pro-platform"
    cluster_version = "1.35"

    # Subnet tags (also consumed by vpc/terragrunt.hcl)
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"        = "1"
      "kubernetes.io/cluster/pro-platform"     = "owned"
    }
    public_subnet_tags = {
      "kubernetes.io/role/elb"                 = "1"
      "kubernetes.io/cluster/pro-platform"     = "owned"
    }

    endpoint_private_access = true
    endpoint_public_access  = false
    public_access_cidrs     = []

    authentication_mode             = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin = true

    cluster_log_types          = ["api", "audit", "authenticator"]
    cluster_log_retention_days = 90

    enable_cluster_encryption = true

    node_groups = {
      system = {
        instance_types = ["t3.large"]
        desired_size   = 3
        min_size       = 3
        max_size       = 6
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
