############################################
# Subnet resolution (no AZ input required)
# - Select by VPC + optional tag or Name
# - Derive the instance AZ from the chosen subnet
############################################

# All subnets in the VPC, optionally narrowed by tag or Name
data "aws_subnets" "by_filters" {
  # We always allow tag/wildcard narrowing; caller can pass none.
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

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
  _input_subnet_id           = var.subnet_ID
  _from_filters              = try(data.aws_subnets.by_filters.ids, [])  # ids is empty if no matches
  _candidates_raw            = concat((_input_subnet_id != "" ? [ _input_subnet_id ] : []), _from_filters)
  subnet_id_candidates       = [for id in local._candidates_raw : id if id != null && trim(id, " ") != ""]

  need_unique                = var.subnet_selection_mode != "first"
  subnet_id_effective        = (
    length(local.subnet_id_candidates) == 0 ? "" :
    local.need_unique
      ? (length(local.subnet_id_candidates) == 1 ? local.subnet_id_candidates[0] : "")
      : sort(local.subnet_id_candidates)[0]
  )
}

# Enforce: must have exactly one (if unique) or at least one (if first)
resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id}.
        Provide subnet_ID or narrow with:
          - subnet_tag_key + subnet_tag_value (e.g., Tier=app)
          - subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# Chosen primary subnet (gives us the AZ too)
data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}

locals {
  # Instance AZ is derived from the selected subnet (no input AZ needed)
  instance_az_effective = try(data.aws_subnet.effective.availability_zone, "")
  primary_subnet_id     = local.subnet_id_effective
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI
#############################################

# HANA node SG id (db1)
data "aws_ssm_parameter" "ec2_hana_sg" {
  # Expects something like: /<env>/security_group/db1/id
  name = "/${var.environment}/security_group/db1/id"
}

# NetWeaver/app node SG id (app1)
data "aws_ssm_parameter" "ec2_nw_sg" {
  # Expects something like: /<env>/security_group/app1/id
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
