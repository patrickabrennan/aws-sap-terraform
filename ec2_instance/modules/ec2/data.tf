############################################
# Subnet resolution (no AZ input required)
# - Select by VPC + optional tag or Name
# - Derive the instance AZ from the chosen subnet
############################################

data "aws_subnets" "by_filters" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Optional exact tag (e.g., Tier=app or sap_relevant=true)
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional Name wildcard (e.g., sap_vpc_* or *private*)
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  # Build candidate pool: explicit ID (if given) + any from filters
  _input_subnet_id = var.subnet_ID
  _from_filters    = try(data.aws_subnets.by_filters.ids, [])

  _candidates_raw = concat(
    (local._input_subnet_id != "" ? [local._input_subnet_id] : []),
    local._from_filters
  )

  subnet_id_candidates = [
    for id in local._candidates_raw : id
    if id != null && trim(id, " ") != ""
  ]

  need_unique = var.subnet_selection_mode != "first"

  subnet_id_effective = (
    length(local.subnet_id_candidates) == 0 ? "" :
    local.need_unique
      ? (length(local.subnet_id_candidates) == 1 ? local.subnet_id_candidates[0] : "")
      : sort(local.subnet_id_candidates)[0]
  )
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id}.
        Provide subnet_ID or narrow with:
          - subnet_tag_key + subnet_tag_value (e.g., Tier=app or sap_relevant=true)
          - subnet_name_wildcard (e.g., "*public*" or "sap_vpc_*")
        Or auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# Chosen primary subnet (use its AZ)
data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

locals {
  # Derived from the selected subnet
  instance_az_effective = try(data.aws_subnet.effective.availability_zone, "")
  primary_subnet_id     = local.subnet_id_effective
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI
#############################################

data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

###########################################
# Resolve IAM Instance Profile name via SSM
###########################################

data "aws_ssm_parameter" "ec2_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2-ha/name"
}

data "aws_ssm_parameter" "ec2_non_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2/name"
}

locals {
  # Optional override; else pick HA/non-HA profile via SSM
  iam_instance_profile_name_effective = (
    var.iam_instance_profile_name_override != ""
      ? var.iam_instance_profile_name_override
      : (var.ha
          ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
          : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
        )
  )

  # Security groups for ENIs:
  resolved_security_group_ids = (
    length(var.security_group_ids) > 0
      ? var.security_group_ids
      : (var.application_code == "hana"
          ? [data.aws_ssm_parameter.ec2_hana_sg.value]
          : [data.aws_ssm_parameter.ec2_nw_sg.value]
        )
  )
}
