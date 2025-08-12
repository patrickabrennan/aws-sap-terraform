############################################
# Subnet resolution (no hardcoding needed)
############################################

# If subnet_ID is NOT given, search by VPC + AZ (+ optional tag filters)
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
  # All candidates from filters (or empty)
  _candidates_from_filters = try(data.aws_subnets.by_filters[0].ids, [])

  # If caller provided subnet_ID, that wins; otherwise use the filtered list
  subnet_id_candidates = var.subnet_ID != "" ? [var.subnet_ID] : local._candidates_from_filters

  # Selection policy: "unique" (must be exactly one) or "first" (take first if many)
  need_unique = lower(var.subnet_selection_mode) != "first"

  subnet_id_effective = (
    length(local.subnet_id_candidates) == 0 ? "" :
    local.need_unique
      ? (length(local.subnet_id_candidates) == 1 ? local.subnet_id_candidates[0] : "")
      : local.subnet_id_candidates[0]
  )
}

# Enforce the selection rule only when we require uniqueness
resource "null_resource" "assert_single_subnet" {
  count = local.need_unique ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
        Refine selection by setting one of:
          - subnet_tag_key + subnet_tag_value       (e.g., Tier=app)
          - subnet_name_wildcard                    (e.g., "*public*" or "*private*")
        Or allow auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# Finally, expose the chosen subnet (resolved by ID, never by filters)
data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI
#############################################

data "aws_ssm_parameter" "ec2_hana_sg" {
  # Expects: /<env>/security_group/db1/id
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  # Expects: /<env>/security_group/app1/id
  name = "/${var.environment}/security_group/app1/id"
}

###########################################
# IAM Instance Profile name via SSM (optional override)
###########################################

data "aws_ssm_parameter" "ec2_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2-ha/name"
}

data "aws_ssm_parameter" "ec2_non_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2/name"
}

locals {
  iam_instance_profile_name_effective = (
    var.iam_instance_profile_name_override != ""
      ? var.iam_instance_profile_name_override
      : (
          var.ha
          ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
          : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
        )
  )

  # Effective security group IDs for the primary ENI:
  # - if caller passes var.security_group_ids, use them
  # - otherwise choose from SSM based on application_code
  resolved_security_group_ids = (
    length(var.security_group_ids) > 0
      ? var.security_group_ids
      : (
          var.application_code == "hana"
            ? [data.aws_ssm_parameter.ec2_hana_sg.value]
            : [data.aws_ssm_parameter.ec2_nw_sg.value]
        )
  )
}

# Ensure SGs resolved
resource "null_resource" "assert_sg_nonempty" {
  lifecycle {
    precondition {
      condition     = length(local.resolved_security_group_ids) > 0
      error_message = "No security groups resolved for instance; pass security_group_ids or ensure SSM SG parameters exist."
    }
  }
}
