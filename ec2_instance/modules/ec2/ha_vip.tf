########################################
# VIP ENI: subnet resolve + NIC create
########################################

# Only evaluate list when VIP is enabled AND vip_subnet_id is empty
data "aws_subnets" "vip_candidates" {
  count = var.enable_vip_eni && var.vip_subnet_id == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional exact tag filter
  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  # Optional Name wildcard (supports '*')
  dynamic "filter" {
    for_each = (var.vip_subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

locals {
  _vip_candidates = var.vip_subnet_id != ""
    ? [var.vip_subnet_id]
    : (
        length(data.aws_subnets.vip_candidates) == 1
        ? data.aws_subnets.vip_candidates[0].ids
        : []
      )

  vip_subnet_id_effective = (
    length(local._vip_candidates) == 1
      ? local._vip_candidates[0]
      : (
          var.vip_subnet_selection_mode == "first" && length(local._vip_candidates) > 1
          ? sort(local._vip_candidates)[0]
          : ""
        )
  )
}

resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0
  lifecycle {
    precondition {
      condition = local.vip_subnet_id_effective != ""
      error_message = <<EOM
VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.
Refine selection by setting one of:
 - vip_subnet_tag_key + vip_subnet_tag_value
 - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
Or allow auto-pick by setting:
 - vip_subnet_selection_mode = "first"
EOM
    }
  }
}

resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  security_groups   = var.security_group_ids
  source_dest_check = false

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-vip"
    environment = var.environment
    role        = "vip"
  })

  depends_on = [null_resource.assert_vip_subnet]
}
