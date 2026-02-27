#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (dev, pre, pro)"
  type        = string

  validation {
    condition     = contains(["dev", "pre", "pro"], var.environment)
    error_message = "Environment must be one of: dev, pre, pro."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

#------------------------------------------------------------------------------
# Optional Variables - NAT Gateway
#------------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets to access internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = <<-EOT
    Use a single NAT Gateway for all AZs (cost optimization).
    - true:  Single NAT (~$32/month) - recommended for dev/staging
    - false: One NAT per AZ (~$32/month * AZs) - recommended for prod (HA)
  EOT
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Optional Variables - Isolated Subnets
#------------------------------------------------------------------------------
variable "create_isolated_subnets" {
  description = "Create isolated subnets (no internet access, for databases)"
  type        = bool
  default     = false
}

variable "isolated_subnet_cidrs" {
  description = "CIDR blocks for isolated subnets (one per AZ)"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Optional Variables - Subnet Tags (for EKS, ECS, etc.)
#------------------------------------------------------------------------------
variable "private_subnet_tags" {
  description = <<-EOT
    Additional tags for private subnets.
    For EKS, include:
    {
      "kubernetes.io/role/internal-elb" = 1
      "kubernetes.io/cluster/CLUSTER_NAME" = "owned"
    }
  EOT
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = <<-EOT
    Additional tags for public subnets.
    For EKS, include:
    {
      "kubernetes.io/role/elb" = 1
      "kubernetes.io/cluster/CLUSTER_NAME" = "owned"
    }
  EOT
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Optional Variables - General
#------------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
