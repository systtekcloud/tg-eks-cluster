#------------------------------------------------------------------------------
# Cluster Outputs
#------------------------------------------------------------------------------
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded CA cert for cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

#------------------------------------------------------------------------------
# IAM Outputs
#------------------------------------------------------------------------------
output "cluster_role_arn" {
  description = "IAM role ARN of the cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN for nodes (needed by Karpenter)"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "IAM role name for nodes"
  value       = aws_iam_role.node.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

#------------------------------------------------------------------------------
# Security Group Outputs
#------------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Security group ID of the cluster control plane"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID of the worker nodes"
  value       = aws_security_group.node.id
}

#------------------------------------------------------------------------------
# Network Outputs
#------------------------------------------------------------------------------
output "cluster_primary_security_group_id" {
  description = "EKS-created security group ID (cluster primary)"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
