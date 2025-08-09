data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use the first two AZs in the region
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  base_tags = merge(
    {
      Name         = "sap_vpc"
      sap_relevant = "true"
      environment  = var.environment
    },
    var.extra_tags
  )
}

# VPC
resource "aws_vpc" "sap_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.base_tags
}

# Internet Gateway
resource "aws_internet_gateway" "sap_igw" {
  vpc_id = aws_vpc.sap_vpc.id

  tags = merge(local.base_tags, { Name = "sap_vpc_igw" })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sap_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sap_igw.id
  }

  tags = merge(local.base_tags, { Name = "sap_vpc_public_rt" })
}

# Two public subnets whose Name includes the AZ
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.sap_vpc.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = merge(local.base_tags, { Name = "sap_vpc_${local.azs[tonumber(each.key)]}" })
}

# Associate all public subnets with public RT
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
