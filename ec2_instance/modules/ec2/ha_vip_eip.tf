############################################
# VIP subnet resolution (per-instance AZ)
############################################

# Look up VIP subnets when enabled and no explicit ID is given
# We fetch TWO lists:
#   - vip_filtered: VPC+AZ plus optional narrowing
#   - vip_az_only:  VPC+AZ only (fallback if filters give 0 results)
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
  _vip_from_filtered = try(data.aws_subnets.vip_filtered[0].ids, [])
  _vip_from_azonly   = try(data.aws_subnets.vip_az_only[0].ids, [])

  _vip_union = coalescelist(local._vip_from_filtered, local._vip_from_azonly)

  vip_candidate_ids = (
    var.vip_subnet_id != ""
      ? [var.vip_subnet_id]
      : (var.enable_vip_eni ? distinct(sort(local._vip_union)) : [])
  )

  vip_need_unique = var.vip_subnet_selection_mode != "first"

  vip_subnet_id_effective = (
    length(local.vip_candidate_ids) == 0 ? "" :
    local.vip_need_unique
      ? (length(local.vip_candidate_ids) == 1 ? local.vip_candidate_ids[0] : "")
      : local.vip_candidate_ids[0]
  )
}

# Enforce rule only when VIP ENI is enabled
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

  # Reuse the same SGs as instance (from SSM lookups in data.tf)
  security_groups = [
    var.application_code == "hana"
      ? data.aws_ssm_parameter.ec2_hana_sg.value
      : data.aws_ssm_parameter.ec2_nw_sg.value
  ]

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
