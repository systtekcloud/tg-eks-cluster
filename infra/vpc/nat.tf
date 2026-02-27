#------------------------------------------------------------------------------
# NAT Gateway Configuration
# 
# Options:
# - enable_nat_gateway = false  → No NAT (isolated private subnets)
# - single_nat_gateway = true   → One NAT for all AZs (cost savings for dev/staging)
# - single_nat_gateway = false  → One NAT per AZ (HA for production)
#------------------------------------------------------------------------------

locals {
  # Determine how many NAT Gateways to create
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
}

#------------------------------------------------------------------------------
# Elastic IPs for NAT Gateways
#------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(
    {
      Name = var.single_nat_gateway ? "${var.environment}-nat-eip" : "${var.environment}-nat-eip-${var.availability_zones[count.index]}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

#------------------------------------------------------------------------------
# NAT Gateways
#------------------------------------------------------------------------------
resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = var.single_nat_gateway ? "${var.environment}-nat" : "${var.environment}-nat-${var.availability_zones[count.index]}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}
