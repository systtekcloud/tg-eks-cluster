#------------------------------------------------------------------------------
# EKS Managed Addons
#------------------------------------------------------------------------------
resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = each.value.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.this]
}
