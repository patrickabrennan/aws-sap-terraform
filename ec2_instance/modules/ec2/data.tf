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

  # Optional exact tag (e.g., Tier=app)
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional Name wildcard (e.g., "*private*")
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  # Candidate IDs: explicit wins; else from filters (or empty)
  subnet_id_candidates = var.subnet_ID != "" ? [var.subnet_ID] : try(data.aws_subnets.by_filters[0].ids, [])

  # Pick one deterministically if allowed
  subnet_id_effective = (
    length(local.subnet_id_candidates) == 1 ? local.subnet_id_candidates[0] :
    (var.subnet_selection_mode == "first" && length(local.subnet_id_candidates) > 1 ? local.subnet_id_candidates[0] : "")
  )
}

# Enforce: must resolve to exactly one ID (unless you passed subnet_ID)
resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
        Provide subnet_ID or narrow with:
          - subnet_tag_key + subnet_tag_value (e.g., Tier=app)
          - subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# ✅ ID-based lookup (cannot return multiple)
data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

#############################################
# SSM lookups for SGs and IAM instance profile
#############################################

data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

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
      : (var.ha
          ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
          : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
        )
  )

  _sg_from_input = try(var.security_group_ids, [])

  resolved_security_group_ids = length(local._sg_from_input) > 0 ? local._sg_from_input : [
    var.application_code == "hana"
      ? data.aws_ssm_parameter.ec2_hana_sg.value
      : data.aws_ssm_parameter.ec2_nw_sg.value
  ]
}
