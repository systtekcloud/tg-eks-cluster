#------------------------------------------------------------------------------
# Cluster Configuration
#------------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID where cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for control plane and nodes"
  type        = list(string)
}

#------------------------------------------------------------------------------
# Endpoint Access
#------------------------------------------------------------------------------
variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access public endpoint"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Authentication
#------------------------------------------------------------------------------
variable "authentication_mode" {
  description = "Authentication mode: API, CONFIG_MAP, or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin" {
  description = "Grant cluster creator admin permissions"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Encryption
#------------------------------------------------------------------------------
variable "enable_cluster_encryption" {
  description = "Enable KMS encryption for secrets"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------
variable "cluster_log_types" {
  description = "Control plane log types to enable"
  type        = list(string)
  default     = []
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

#------------------------------------------------------------------------------
# Node Groups
#------------------------------------------------------------------------------
variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

#------------------------------------------------------------------------------
# Addons
#------------------------------------------------------------------------------
variable "addons" {
  description = "Map of EKS addons to install with versions"
  type = map(object({
    version = string
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
