############################################
# Subnet resolution (no hardcoding needed)
############################################

# When caller didn't pass subnet_ID, search by VPC + AZ (+ optional narrowing)
data "aws_subnets" "az_only" {
  count = var.subnet_ID == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

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

  # Optional Name filter (supports wildcards)
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  # explicit input (if any)
  _subnet_id_input = trimspace(coalesce(var.subnet_ID, ""))

  # candidates from lookups (safe tries)
  _candidates_from_filters = var.subnet_ID == "" ? try(data.aws_subnets.by_filters[0].ids, []) : []
  _candidates_from_azonly  = var.subnet_ID == "" ? try(data.aws_subnets.az_only[0].ids,   []) : []

  # precedence: explicit > filtered > az_only
  _subnet_id_candidates_raw = (
    local._subnet_id_input != ""     ? [local._subnet_id_input] :
    length(local._candidates_from_filters) > 0 ? local._candidates_from_filters :
    local._candidates_from_azonly
  )

  # sanitize & make deterministic
  subnet_id_candidates = distinct(sort([
    for id in local._subnet_id_candidates_raw : id
    if id != null && trimspace(id) != ""
  ]))

  need_unique       = var.subnet_selection_mode != "first"
  has_any           = length(local.subnet_id_candidates) >= 1
  is_exactly_one    = length(local.subnet_id_candidates) == 1

  subnet_condition  = local.need_unique ? local.is_exactly_one : local.has_any

  subnet_id_effective = (
    local.need_unique
      ? (local.is_exactly_one ? local.subnet_id_candidates[0] : "")
      : (local.has_any ? local.subnet_id_candidates[0] : "")
  )
}

# Friendly assertion
resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_condition
      error_message = <<-EOT
        Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
        Provide subnet_ID or narrow with:
          - subnet_tag_key + subnet_tag_value
          - subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or allow auto-pick by setting:
          - subnet_selection_mode = "first"
      EOT
    }
  }
}

# Always read by ID -> no "multiple matched" here
data "aws_subnet" "effective" {
  id         = local.subnet_id_effective
  depends_on = [null_resource.assert_single_subnet]
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI  #
#############################################

# HANA node SG id (db1)
data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

# NetWeaver/app node SG id (app1)
data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

###########################################
# Resolved security groups for ENIs
###########################################
locals {
  # If caller passes SGs use them; else choose from SSM by application_code
  resolved_security_group_ids = length(var.security_group_ids) > 0
    ? var.security_group_ids
    : (
        var.application_code == "hana"
          ? [data.aws_ssm_parameter.ec2_hana_sg.value]
          : [data.aws_ssm_parameter.ec2_nw_sg.value]
      )
}
