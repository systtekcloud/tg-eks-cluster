#------------------------------------------------------------------------------
# VPC Endpoints
# Gateway endpoints: S3, DynamoDB (free)
# Interface endpoints: ECR, Secrets Manager, STS, etc. (~$7/month each)
#------------------------------------------------------------------------------

locals {
  create_interface_endpoints = length(var.interface_endpoints) > 0
}

#------------------------------------------------------------------------------
# Security Group — shared across all interface endpoints (shared_endpoint_sg = true)
#------------------------------------------------------------------------------
resource "aws_security_group" "endpoints" {
  count       = local.create_interface_endpoints && var.shared_endpoint_sg ? 1 : 0
  name        = "${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc-endpoints-sg"
  })
}

#------------------------------------------------------------------------------
# Security Groups — individual per endpoint (shared_endpoint_sg = false)
#------------------------------------------------------------------------------
resource "aws_security_group" "endpoint_individual" {
  for_each = local.create_interface_endpoints && !var.shared_endpoint_sg ? toset(var.interface_endpoints) : toset([])

  name        = "${var.environment}-vpce-${replace(each.key, ".", "-")}-sg"
  description = "Security group for ${each.key} VPC Endpoint"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-vpce-${replace(each.key, ".", "-")}-sg"
  })
}

#------------------------------------------------------------------------------
# Gateway Endpoints (S3, DynamoDB) — Free
#------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(var.gateway_endpoints)

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(var.tags, {
    Name = "${var.environment}-vpce-${each.key}"
  })
}

#------------------------------------------------------------------------------
# Interface Endpoints — Paid (~$7/month each)
#------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = var.shared_endpoint_sg ? [
    aws_security_group.endpoints[0].id
  ] : [
    aws_security_group.endpoint_individual[each.key].id
  ]

  tags = merge(var.tags, {
    Name = "${var.environment}-vpce-${replace(each.key, ".", "-")}"
  })
}
