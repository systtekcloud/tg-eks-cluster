#------------------------------------------------------------------------------
# Cluster Security Group (Control Plane)
#------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress: Nodes → Control Plane (API server)
resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  description              = "Nodes to cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

# Ingress: VPC CIDR → Control Plane (internal access via Tailscale, etc.)
resource "aws_security_group_rule" "cluster_ingress_vpc_443" {
  description       = "VPC internal to cluster API"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = [var.vpc_cidr]
}

# Egress: Control Plane → Nodes (ephemeral ports)
resource "aws_security_group_rule" "cluster_egress_nodes_ephemeral" {
  description              = "Cluster to nodes ephemeral ports"
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

# Egress: Control Plane → Nodes (HTTPS for webhooks, metrics)
resource "aws_security_group_rule" "cluster_egress_nodes_443" {
  description              = "Cluster to nodes HTTPS"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

#------------------------------------------------------------------------------
# Node Security Group
#------------------------------------------------------------------------------
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress: Node-to-node (all traffic for pod communication)
resource "aws_security_group_rule" "node_ingress_self" {
  description       = "Node to node all ports/protocols"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  self              = true
}

# Ingress: Control Plane → Nodes (HTTPS)
resource "aws_security_group_rule" "node_ingress_cluster_443" {
  description              = "Cluster to nodes HTTPS"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Ingress: Control Plane → Nodes (kubelet API)
resource "aws_security_group_rule" "node_ingress_cluster_10250" {
  description              = "Cluster to nodes kubelet"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Ingress: Node-to-node kubelet (metrics-server)
resource "aws_security_group_rule" "node_ingress_self_10250" {
  description       = "Node to node kubelet for metrics-server"
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  self              = true
}

# Ingress: Control Plane → Nodes (Prometheus scraping)
resource "aws_security_group_rule" "node_ingress_cluster_prometheus" {
  description              = "Cluster to nodes Prometheus"
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Ingress: Control Plane → Nodes (Admission webhooks: Istio 15017, Kyverno 9443, etc.)
resource "aws_security_group_rule" "node_ingress_cluster_webhooks" {
  for_each = toset(["8443", "9443", "15017"])

  description              = "Cluster to nodes webhook port ${each.key}"
  type                     = "ingress"
  from_port                = tonumber(each.key)
  to_port                  = tonumber(each.key)
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Ingress: Control Plane → Nodes (Istio sidecar metrics)
resource "aws_security_group_rule" "node_ingress_cluster_istio_metrics" {
  description              = "Cluster to nodes Istio sidecar metrics"
  type                     = "ingress"
  from_port                = 15090
  to_port                  = 15090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Ingress: Node-to-node (Istiod XDS)
resource "aws_security_group_rule" "node_ingress_self_istiod_xds" {
  for_each = toset(["15010", "15012"])

  description       = "Node to node Istiod XDS port ${each.key}"
  type              = "ingress"
  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  self              = true
}

# Egress: Nodes → anywhere (pull images, AWS APIs, etc.)
resource "aws_security_group_rule" "node_egress_all" {
  description       = "Nodes egress to anywhere"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Egress: Node-to-node kubelet (metrics-server responses)
resource "aws_security_group_rule" "node_egress_self_10250" {
  description       = "Node to node kubelet egress"
  type              = "egress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  self              = true
}
