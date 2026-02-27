#------------------------------------------------------------------------------
# Public Route Table
# - Single route table for all public subnets
# - Routes to Internet Gateway
#------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.environment}-public-rt"
    },
    var.tags
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#------------------------------------------------------------------------------
# Private Route Tables
# - One per AZ if multi-NAT, single if single-NAT, none if no NAT
# - Routes to NAT Gateway (if enabled)
#------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = var.single_nat_gateway ? "${var.environment}-private-rt" : "${var.environment}-private-rt-${var.availability_zones[count.index]}"
    },
    var.tags
  )
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

#------------------------------------------------------------------------------
# Isolated Route Tables (no internet access)
#------------------------------------------------------------------------------
resource "aws_route_table" "isolated" {
  count = var.create_isolated_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.environment}-isolated-rt"
    },
    var.tags
  )
}

resource "aws_route_table_association" "isolated" {
  count = var.create_isolated_subnets ? length(var.isolated_subnet_cidrs) : 0

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated[0].id
}
