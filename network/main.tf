provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "sap_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "sap_vpc"
    sap_relevant = "true"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "sap_igw" {
  vpc_id = aws_vpc.sap_vpc.id

  tags = {
    Name         = "sap_vpc_igw"
    sap_relevant = "true"
  }
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.sap_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name         = "sap_vpc_public_1"
    sap_relevant = "true"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.sap_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name         = "sap_vpc_public_2"
    sap_relevant = "true"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sap_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sap_igw.id
  }

  tags = {
    Name         = "sap_vpc_public_rt"
    sap_relevant = "true"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
