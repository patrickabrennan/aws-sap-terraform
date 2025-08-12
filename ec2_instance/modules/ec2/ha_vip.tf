############################################
# VIP subnet resolution (per-instance AZ)
############################################

# Only look up VIP subnets when the feature is enabled and no explicit ID is given
data "aws_subnets" "vip" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional exact tag
  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  # Optional Name filter
  dynamic "filter" {
    for_each = (var.vip_subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

locals {
  _vip_candidates_from_filters = try(data.aws_subnets.vip[0].ids, [])

  # Normalize input (turn null into "")
  _vip_id_input = try(coalesce(var.vip_subnet_id, ""), "")

  # Build raw candidate list (only when feature enabled)
  _vip_candidate_ids_raw = (
    _vip_id_input != "" ? [_vip_id_input] :
    (var.enable_vip_eni ? _vip_candidates_from_filters : [])
  )

  # Remove nulls and empty strings
  vip_candidate_ids = [for id in local._vip_candidate_ids_raw : id if id != null && trim(id) != ""]

  vip_need_unique   = lower(var.vip_subnet_selection_mode) != "first"
  _vip_picked_first = length(local.vip_candidate_ids) > 0 ? sort(local.vip_candidate_ids)[0] : ""

  vip_subnet_id_effective = (
    length(local.vip_candidate_ids) == 0 ? "" :
    local.vip_need_unique
      ? (length(local.vip_candidate_ids) == 1 ? local.vip_candidate_ids[0] : "")
      : local._vip_picked_first
  )

  vip_condition = local.vip_need_unique ? (local.vip_subnet_id_effective != "") : (length(local.vip_candidate_ids) > 0)

  vip_error_unique = <<-EOT
    VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.
    Refine selection by setting one of:
      - vip_subnet_tag_key + vip_subnet_tag_value
      - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
    Or allow auto-pick by setting:
      - vip_subnet_selection_mode = "first"
  EOT

  vip_error_none = <<-EOT
    VIP ENI cannot be created: no subnet matched in ${var.vpc_id} / ${var.availability_zone}.
    Provide vip_subnet_id or narrow with:
      - vip_subnet_tag_key + vip_subnet_tag_value
      - vip_subnet_name_wildcard
  EOT

  vip_error_message = local.vip_need_unique ? local.vip_error_unique : local.vip_error_none
}

# Enforce rule only when VIP ENI is enabled
resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_condition
      error_message = local.vip_error_message
    }
  }
}

# Create the VIP ENI (if enabled)
resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

  # Reuse the same SGs as instance (resolved in data.tf locals)
  security_groups = local.resolved_security_group_ids

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-vip"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
    }
  )

  depends_on = [
    null_resource.assert_vip_subnet,
    null_resource.assert_single_subnet,
    null_resource.assert_sg_nonempty
  ]
}
