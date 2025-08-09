data "aws_ssm_parameter" "ebs_kms" {
  name = "/${var.environment}/kms/ebs/arn"
}

data "aws_ssm_parameter" "ec2_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2-ha/name"
}

data "aws_ssm_parameter" "ec2_non_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2/name"
}

data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

#data "aws_subnet" "selected" {
#  id = var.subnet_ID
#}

locals {
  # exactly one subnet must match
  subnet_id_effective = length(data.aws_subnets.by_filters.ids) == 1 ? data.aws_subnets.by_filters.ids[0] : ""
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = "Subnet lookup did not resolve to exactly one subnet. Check AZ/tag filters."
    }
  }
}

data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

data "aws_subnets" "by_filters" {
  count = var.subnet_ID == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Add more filters if needed to ensure exactly ONE match
  # filter { name = "availability-zone"; values = [var.availability_zone] }
  # filter { name = "tag:Name"; values = ["sap-public-a"] }
}

