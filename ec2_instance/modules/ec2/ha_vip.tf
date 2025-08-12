############################################
# VIP subnet resolution (per-instance AZ)
############################################

# Only look up VIP subnets when enabled and no explicit ID given
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

  # Optional exact tag (e.g., key=Tier, value=app)
  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  # Optional Name tag wildcard (e.g., "*public*" or "*private*")
  dynamic "filter" {
    for_each = (var.vip_subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

locals {
  _vip_candidate_ids_raw = (
    var.vip_subnet_id != ""
      ? [trimspace(var.vip_subnet_id)]
      : (var.enable_vip_eni ? try(data.aws_subnets.vip[0].ids, []) : [])
  )

  vip_candidate_ids = distinct(sort([
    for id in local._vip_candidate_ids_raw : id
    if id != null && trimspace(id) != ""
  ]))

  vip_need_unique         = var.vip_subnet_selection_mode != "first"
  vip_has_any             = length(local.vip_candidate_ids) >= 1
  vip_is_exactly_one      = length(local.vip_candidate_ids) == 1

  vip_subnet_condition    = local.vip_need_unique ? local.vip_is_exactly_one : local.vip_has_any

  vip_subnet_id_effective = (
    local.vip_need_unique
      ? (local.vip_is_exactly_one ? local.vip_candidate_ids[0] : "")
      : (local.vip_has_any ? local.vip_candidate_ids[0] : "")
  )
}

# Enforce rule only when VIP ENI is enabled
resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_subnet_condition
      error_message = <<-EOT
        VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.
        Refine selection by setting one of:
          - vip_subnet_tag_key + vip_subnet_tag_value
          - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or allow auto-pick by setting:
          - vip_subnet_selection_mode = "first"
      EOT
    }
  }
}

# Create the VIP ENI (if enabled)
resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

  # Reuse the same SG policy as the primary ENI (resolved in data.tf)
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

  lifecycle {
    precondition {
      condition     = length(local.resolved_security_group_ids) > 0
      error_message = "No security groups resolved for VIP ENI. Pass security_group_ids or ensure SSM parameters exist."
    }
  }

  depends_on = [null_resource.assert_vip_subnet]
}
