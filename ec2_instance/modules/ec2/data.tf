############################################
# Subnet resolution (AZ-aware, deterministic)
# - Prefer caller's subnet_ID (per-AZ mapping)
# - Else: VPC + instance AZ + tag/name filters
# - Derive instance AZ from inputs/metadata
############################################

# If the caller provided a subnet_ID, we can derive the AZ from it
data "aws_subnet" "from_input" {
  count = var.subnet_ID != "" ? 1 : 0
  id    = var.subnet_ID
}

locals {
  # Determine the AZ we should use:
  # 1) var.availability_zone (root should pass this)
  # 2) else, derive from the provided subnet_ID
  instance_az_requested = coalesce(
    try(trim(var.availability_zone), null),
    try(data.aws_subnet.from_input[0].availability_zone, null)
  )
}

# Ensure we know the AZ before continuing
resource "null_resource" "assert_az_known" {
  lifecycle {
    precondition {
      condition     = local.instance_az_requested != null && local.instance_az_requested != ""
      error_message = <<-EOT
        availability_zone is not known: neither 'availability_zone' was passed
        nor could it be derived from 'subnet_ID'.
        Pass availability_zone from the root module, or provide subnet_ID.
      EOT
    }
  }
}

# When subnet_ID isn't provided, search inside the requested AZ only
data "aws_subnets" "by_filters" {
  count = (var.subnet_ID == "" ? 1 : 0)

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Constrain to the instance's AZ so we don't mix AZs
  filter {
    name   = "availability-zone"
    values = [local.instance_az_requested]
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

  depends_on = [null_resource.assert_az_known]
}

locals {
  # Candidate pool is either the explicit subnet_ID or the filtered list
  _ids_from_filters = try(data.aws_subnets.by_filters[0].ids, [])

  need_unique = var.subnet_selection_mode != "first"

  # Final selection:
  # - If caller gave subnet_ID => use it
  # - Else "unique" requires exactly one match
  # - Else "first" picks the first (sorted) match if any
  subnet_id_effective = (
    var.subnet_ID != "" ? var.subnet_ID :
    (
      local.need_unique
        ? (length(local._ids_from_filters) == 1 ? local._ids_from_filters[0] : "")
        : (length(local._ids_from_filters) > 0  ? sort(local._ids_from_filters)[0] : "")
    )
  )
}

# Fail fast with a clear message if nothing resolved
resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id} (AZ: ${local.instance_az_requested}).
        Provide subnet_ID or narrow with:
          - subnet_tag_key + subnet_tag_value (e.g., Tier=app or sap_relevant=true)
          - subnet_name_wildcard (e.g., "*public*" or "sap_vpc_*")
        Or auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# Resolve the chosen subnet for metadata/confirmation
data "aws_subnet" "effective" {
  count = local.subnet_id_effective != "" ? 1 : 0
  id    = local.subnet_id_effective
}

locals {
  primary_subnet_id     = local.subnet_id_effective
  # Should match instance_az_requested; keep fallback to requested AZ for plan-safety
  instance_az_effective = try(data.aws_subnet.effective[0].availability_zone, local.instance_az_requested)
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















/*
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
*/
