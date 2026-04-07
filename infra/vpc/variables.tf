#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------
variable "project_name" {
  description = "Project name"
  type        = string
}

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
# Optional Variables - Flow Logs
#------------------------------------------------------------------------------
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to S3"
  type        = bool
  default     = false
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture: ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in S3"
  type        = number
  default     = 30
}

variable "enable_flow_logs_access_logs" {
  description = "Enable server access logging for the flow logs bucket"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Optional Variables - VPC Endpoints
#------------------------------------------------------------------------------
variable "gateway_endpoints" {
  description = "List of Gateway endpoints to create (s3, dynamodb) — free"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for e in var.gateway_endpoints : contains(["s3", "dynamodb"], e)])
    error_message = "Gateway endpoints must be 's3' or 'dynamodb'."
  }
}

variable "interface_endpoints" {
  description = "List of Interface endpoints to create (e.g., ecr.api, ecr.dkr, secretsmanager, sts, ssm, logs) — ~$7/month each"
  type        = list(string)
  default     = []
}

variable "shared_endpoint_sg" {
  description = "Use a shared Security Group for all interface endpoints (true) or individual SGs per endpoint (false)"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region — used for VPC endpoint service names (e.g. com.amazonaws.eu-west-1.s3)"
  type        = string
}

#------------------------------------------------------------------------------
# Optional Variables - General
#------------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
