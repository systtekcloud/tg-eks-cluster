#------------------------------------------------------------------------------
# CloudWatch Log Group for Control Plane Logs
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks" {
  count = length(var.cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = var.tags
}

#------------------------------------------------------------------------------
# EKS Cluster
#------------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
    security_group_ids      = [aws_security_group.cluster.id]
  }

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin
  }

  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = merge(var.tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.eks,
  ]
}
