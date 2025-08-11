# Security group IDs published by your security_group workspace via SSM.
# Adjust the parameter names if your path differs.
data "aws_ssm_parameter" "app1_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

data "aws_ssm_parameter" "db1_sg" {
  name = "/${var.environment}/security_group/db1/id"
}




/*
data "aws_ssm_parameter" "ec2_hana_sg" {
  # Path produced by the security_group workspace:
  # /<env>/security_group/<sg_name>/id
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}


# Discover the VPC created by the network workspace
#data "aws_vpc" "sap" {
#  tags = {
#    Name         = "sap_vpc"
#    sap_relevant = "true"
#  }
#}

data "aws_vpc" "sap" {
  tags = {
    Name         = "sap_vpc"
    sap_relevant = "true"
    environment  = var.environment
  }
}


# Find subnets in that VPC that match your naming convention
data "aws_subnets" "public_named" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sap.id]
  }

  filter {
    name   = "tag:Name"
    values = ["sap_vpc_*"]
  }
}

# Load each to verify it's public (map_public_ip_on_launch = true)
data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.public_named.ids)
  id       = each.value
}

locals {
  public_subnet_ids = [
    for s in data.aws_subnet.details : s.id
    if s.map_public_ip_on_launch == true
  ]
}
*/
