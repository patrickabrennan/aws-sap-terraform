############################################
# Subnet resolution (no hardcoding needed)
############################################

data "aws_subnets" "by_filters" {
  count = var.subnet_ID == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional exact tag match (e.g., Tier = app)
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional Name filter (supports wildcards if Name tags are consistent)
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  _candidates_from_filters   = try(data.aws_subnets.by_filters[0].ids, [])
  _subnet_id_input           = try(coalesce(var.subnet_ID, ""), "")

  # remove null/empty values (use trimspace, not trim)
  _subnet_id_candidates_raw  = local._subnet_id_input != "" ? [local._subnet_id_input] : local._candidates_from_filters
  subnet_id_candidates       = [for id in local._subnet_id_candidates_raw : id if id != null && trimspace(id) != ""]

  need_unique   = lower(var.subnet_selection_mode) != "first"
  _picked_first = length(local.subnet_id_candidates) > 0 ? sort(local.subnet_id_candidates)[0] : ""

  subnet_id_effective = (
    length(local.subnet_id_candidates) == 0 ? "" :
    local.need_unique
      ? (length(local.subnet_id_candidates) == 1 ? local.subnet_id_candidates[0] : "")
      : local._picked_first
  )

  subnet_condition = local.need_unique ? (local.subnet_id_effective != "") : (length(local.subnet_id_candidates) > 0)

  subnet_error_unique = <<-EOT
    Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
    Refine selection by setting one of:
      - subnet_tag_key + subnet_tag_value       (e.g., Tier=app)
      - subnet_name_wildcard                    (e.g., "*public*" or "*private*")
    Or allow auto-pick by setting:
      - subnet_selection_mode = "first"
  EOT

  subnet_error_none = <<-EOT
    No subnets matched in ${var.vpc_id} / ${var.availability_zone}.
    Provide subnet_ID or narrow with:
      - subnet_tag_key + subnet_tag_value
      - subnet_name_wildcard (e.g., "*public*" or "*private*")
  EOT

  subnet_error_message = local.need_unique ? local.subnet_error_unique : local.subnet_error_none
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_condition
      error_message = local.subnet_error_message
    }
  }
}

data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI  #
#############################################

data "aws_ssm_parameter" "ec2_hana_sg" { name = "/${var.environment}/security_group/db1/id" }
data "aws_ssm_parameter" "ec2_nw_sg"   { name = "/${var.environment}/security_group/app1/id" }

###########################################
# Resolve IAM Instance Profile name via SSM
###########################################

data "aws_ssm_parameter" "ec2_ha_instance_profile"     { name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2-ha/name" }
data "aws_ssm_parameter" "ec2_non_ha_instance_profile" { name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2/name" }

locals {
  iam_instance_profile_name_effective = (
    var.iam_instance_profile_name_override != ""
      ? var.iam_instance_profile_name_override
      : (var.ha
          ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
          : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value)
  )

  resolved_security_group_ids = (
    length(var.security_group_ids) > 0
      ? var.security_group_ids
      : (var.application_code == "hana"
           ? [data.aws_ssm_parameter.ec2_hana_sg.value]
           : [data.aws_ssm_parameter.ec2_nw_sg.value])
  )
}

resource "null_resource" "assert_sg_nonempty" {
  lifecycle {
    precondition {
      condition     = length(local.resolved_security_group_ids) > 0
      error_message = "No security groups resolved for ENI. Pass security_group_ids or ensure SSM paths exist."
    }
  }
}
