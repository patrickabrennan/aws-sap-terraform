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
data "aws_subnet" "by_id" {
  count = var.subnet_ID != "" ? 1 : 0
  id    = var.subnet_ID
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

locals {
  subnet_id_effective = (
    var.subnet_ID != ""
    ? data.aws_subnet.by_id[0].id
    : (
        length(data.aws_subnets.by_filters[0].ids) == 1
        ? data.aws_subnets.by_filters[0].ids[0]
        : ""
      )
  )
}

