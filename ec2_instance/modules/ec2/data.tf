############################################
# Subnet resolution (no hardcoding needed)
############################################

data "aws_subnets" "az_only" {
  count = var.subnet_ID == "" ? 1 : 0
  filter { name = "vpc-id"            values = [var.vpc_id] }
  filter { name = "availability-zone" values = [var.availability_zone] }
}

data "aws_subnets" "by_filters" {
  count = var.subnet_ID == "" ? 1 : 0
  filter { name = "vpc-id"            values = [var.vpc_id] }
  filter { name = "availability-zone" values = [var.availability_zone] }

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
  _subnet_id_input        = trimspace(coalesce(var.subnet_ID, ""))
  _candidates_from_filters = var.subnet_ID == "" ? try(data.aws_subnets.by_filters[0].ids, []) : []
  _candidates_from_azonly  = var.subnet_ID == "" ? try(data.aws_subnets.az_only[0].ids,   []) : []

  _subnet_id_candidates_raw = (
    local._subnet_id_input != "" ? [local._subnet_id_input] :
    length(local._candidates_from_filters) > 0 ? local._candidates_from_filters :
    local._candidates_from_azonly
  )

  subnet_id_candidates = distinct(sort([
    for id in local._subnet_id_candidates_raw : id
    if id != null && trimspace(id) != ""
  ]))

  need_unique      = var.subnet_selection_mode != "first"
  has_any          = length(local.subnet_id_candidates) >= 1
  is_exactly_one   = length(local.subnet_id_candidates) == 1
  subnet_condition = local.need_unique ? local.is_exactly_one : local.has_any

  subnet_id_effective = (
    local.need_unique
      ? (local.is_exactly_one ? local.subnet_id_candidates[0] : "")
      : (local.has_any ? local.subnet_id_candidates[0] : "")
  )
}

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

data "aws_subnet" "effective" {
  id         = local.subnet_id_effective
  depends_on = [null_resource.assert_single_subnet]
}

#############################################
# SG IDs read from SSM for ENIs / VIP ENI  #
#############################################

data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

###########################################
# Resolved security groups for ENIs
###########################################

locals {
  # Prefer caller-supplied SGs, else fall back to SSM based on application_code
  _sg_from_input = try(var.security_group_ids, [])

  _sg_from_ssm = var.application_code == "hana"
    ? [data.aws_ssm_parameter.ec2_hana_sg.value]
    : [data.aws_ssm_parameter.ec2_nw_sg.value]

  resolved_security_group_ids = length(local._sg_from_input) > 0
    ? local._sg_from_input
    : local._sg_from_ssm
}
