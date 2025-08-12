############################################
# VIP subnet resolution (per-instance AZ)
############################################

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

locals {
  _vip_candidates_from_filters = try(data.aws_subnets.vip[0].ids, [])
  vip_candidate_ids            = var.vip_subnet_id != "" ? [var.vip_subnet_id] : (var.enable_vip_eni ? local._vip_candidates_from_filters : [])

  vip_need_unique  = lower(var.vip_subnet_selection_mode) != "first"
  _vip_picked_first = length(local.vip_candidate_ids) > 0 ? sort(local.vip_candidate_ids)[0] : ""

  vip_subnet_id_effective = (
    length(local.vip_candidate_ids) == 0 ? "" :
    local.vip_need_unique
      ? (length(local.vip_candidate_ids) == 1 ? local.vip_candidate_ids[0] : "")
      : local._vip_picked_first
  )

  # Inline conditional (single line)
  vip_condition      = local.vip_need_unique ? (local.vip_subnet_id_effective != "") : (length(local.vip_candidate_ids) > 0)

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

resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_condition
      error_message = local.vip_error_message
    }
  }
}

resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

  security_groups = (
    length(var.security_group_ids) > 0
      ? var.security_group_ids
      : (var.application_code == "hana" ? [data.aws_ssm_parameter.ec2_hana_sg.value] : [data.aws_ssm_parameter.ec2_nw_sg.value])
  )

  depends_on = [null_resource.assert_sg_nonempty]

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
