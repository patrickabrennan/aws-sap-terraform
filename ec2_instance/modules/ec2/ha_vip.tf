############################################
# VIP subnet resolution (per-instance AZ)
############################################

# Filtered search (when VIP enabled and no explicit vip_subnet_id)
data "aws_subnets" "vip_filtered" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  dynamic "filter" {
    for_each = (var.vip_subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

# AZ-only fallback (VIP)
data "aws_subnets" "vip_az_only" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

locals {
  _vip_from_input   = (var.enable_vip_eni && var.vip_subnet_id != "") ? [var.vip_subnet_id] : []
  _vip_from_filters = (var.enable_vip_eni && var.vip_subnet_id == "") ? try(data.aws_subnets.vip_filtered[0].ids, []) : []
  _vip_from_azonly  = (var.enable_vip_eni && var.vip_subnet_id == "") ? try(data.aws_subnets.vip_az_only[0].ids, []) : []

  _vip_pool = length(local._vip_from_filters) > 0 ? local._vip_from_filters : local._vip_from_azonly

  _vip_raw = concat(local._vip_from_input, local._vip_pool)

  vip_candidate_ids = sort(distinct([
    for id in local._vip_raw : trimspace(id)
    if id != null && trimspace(id) != ""
  ]))

  vip_subnet_id_effective = (
    length(local.vip_candidate_ids) == 1
      ? local.vip_candidate_ids[0]
      : (
          var.vip_subnet_selection_mode == "first" && length(local.vip_candidate_ids) > 1
            ? local.vip_candidate_ids[0]
            : ""
        )
  )
}

resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = <<-EOT
        VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.
        Refine selection by setting one of:
          - vip_subnet_tag_key + vip_subnet_tag_value
          - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or auto-pick by setting:
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

  # Reuse the same SGs as instance
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
