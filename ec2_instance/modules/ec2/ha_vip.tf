############################################
# VIP subnet resolution (no AZ input)
# - Select VIP candidate subnets by VPC + tags/Name
# - Constrain to the instance's AZ (so the ENI can attach)
# - Avoid apply-time values in for_each/count
############################################

# When an explicit VIP subnet is not provided, look up subnets in the instance's AZ.
# All inputs used here are plan-known (vars, data, locals), so planning is stable.
data "aws_subnets" "vip_in_instance_az" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Constrain to the instance's AZ so the ENI can attach there
  filter {
    name   = "availability-zone"
    values = [local.instance_az_effective]
  }

  # Optional narrowing: tag filter
  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  # Optional narrowing: Name wildcard
  dynamic "filter" {
    for_each = var.vip_subnet_name_wildcard != "" ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

locals {
  # Candidate pool:
  # 1) explicit vip_subnet_id (if provided)
  # 2) else the list discovered in THIS instance's AZ
  _vip_candidates = (
    var.vip_subnet_id != ""
    ? [var.vip_subnet_id]
    : try(data.aws_subnets.vip_in_instance_az[0].ids, [])
  )

  # Selection policy
  _vip_need_unique = var.vip_subnet_selection_mode != "first"

  # Final choice:
  # - If no candidates: fallback to primary subnet (same AZ by definition)
  # - If "unique": require exactly one
  # - If "first": take the first (sorted for determinism)
  vip_subnet_id_effective = (
    length(local._vip_candidates) == 0
      ? local.primary_subnet_id
      : (
          local._vip_need_unique
            ? (length(local._vip_candidates) == 1 ? local._vip_candidates[0] : "")
            : sort(local._vip_candidates)[0]
        )
  )
}

# Fail fast with a helpful message when we cannot select a subnet
resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = <<-EOT
        VIP ENI cannot be created: no suitable subnet found in VPC ${var.vpc_id} within AZ ${local.instance_az_effective}.
        Try one of:
          - Set vip_subnet_tag_key + vip_subnet_tag_value to narrow to intended subnets
          - Set vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
          - Set vip_subnet_selection_mode = "first" to auto-pick when multiple match
          - Provide vip_subnet_id explicitly
      EOT
    }
  }
}

# Create the VIP ENI in the resolved subnet (same AZ as the instance)
resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

  # Reuse the resolved SGs from data.tf
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
}
