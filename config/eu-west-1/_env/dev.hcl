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
  # EKS Configuration
  #----------------------------------------------------------------------------
  eks_config = {
    cluster_name    = "dev-platform"
    cluster_version = "1.35"

    # Subnet tags (also consumed by vpc/terragrunt.hcl)
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb"        = "1"
      "kubernetes.io/cluster/dev-platform"     = "owned"
    }
    public_subnet_tags = {
      "kubernetes.io/role/elb"                 = "1"
      "kubernetes.io/cluster/dev-platform"     = "owned"
    }

    # Dev: public access para facilitar desarrollo inicial
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]  # Restringir a tu IP en producción

    # Authentication
    authentication_mode             = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin = true

    # Logging (mínimo en dev para ahorro)
    cluster_log_types          = []
    cluster_log_retention_days = 7

    # Encryption (disabled en dev para ahorro)
    enable_cluster_encryption = false

    # Node groups
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

    # Addons - verificar versiones actuales con:
    # aws eks describe-addon-versions --kubernetes-version 1.35 --addon-name <name>
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
