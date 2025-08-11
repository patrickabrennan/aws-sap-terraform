##############################################
# Module data sources + PRIMARY subnet resolve
##############################################

# Keep only if you use these SSM params
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

# When subnet_ID is empty, enumerate subnets in VPC+AZ, with optional filters
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

  # Optional exact tag filter
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional Name wildcard (supports '*')
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  _primary_candidates = (var.subnet_ID != "" ? [var.subnet_ID] : (length(data.aws_subnets.by_filters) == 1 ? data.aws_subnets.by_filters[0].ids : []))

  subnet_id_effective = (length(local._primary_candidates) == 1
    ? local._primary_candidates[0]
    : (var.subnet_selection_mode == "first" && length(local._primary_candidates) > 1
      ? sort(local._primary_candidates)[0]
      : ""))
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<EOM
Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
Refine selection by setting one of:
 - subnet_tag_key + subnet_tag_value       (e.g., Tier=app)
 - subnet_name_wildcard                    (e.g., "*public*" or "*private*")
Or allow auto-pick by setting:
 - subnet_selection_mode = "first"
EOM
    }
  }
}

data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}
