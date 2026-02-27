#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = "${var.environment}-vpc"
    },
    var.tags
  )
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.environment}-igw"
    },
    var.tags
  )
}

#------------------------------------------------------------------------------
# Public Subnets
#------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.environment}-public-${var.availability_zones[count.index]}"
      Tier = "public"
    },
    var.public_subnet_tags,
    var.tags
  )
}

#------------------------------------------------------------------------------
# Private Subnets
#------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name = "${var.environment}-private-${var.availability_zones[count.index]}"
      Tier = "private"
    },
    var.private_subnet_tags,
    var.tags
  )
}

#------------------------------------------------------------------------------
# Isolated Subnets (for databases, no internet access)
#------------------------------------------------------------------------------
resource "aws_subnet" "isolated" {
  count = var.create_isolated_subnets ? length(var.isolated_subnet_cidrs) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name = "${var.environment}-isolated-${var.availability_zones[count.index]}"
      Tier = "isolated"
    },
    var.tags
  )
}
