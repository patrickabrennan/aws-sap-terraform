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
  vip_candidate_ids = (var.vip_subnet_id != "" ? [var.vip_subnet_id] : (var.enable_vip_eni ? try(data.aws_subnets.vip[0].ids, []) : []))

  # **Fix**: single-line ternary
  vip_subnet_id_effective = (length(local.vip_candidate_ids) == 1
    ? local.vip_candidate_ids[0]
    : (var.vip_subnet_selection_mode == "first" && length(local.vip_candidate_ids) > 1 ? local.vip_candidate_ids[0] : "")
  )
}

resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = <<-EOT
        VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.
        Provide vip_subnet_id or narrow with:
          - vip_subnet_tag_key + vip_subnet_tag_value
          - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or allow auto-pick by setting:
          - vip_subnet_selection_mode = "first"
      EOT
    }
  }
}

resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

  # Reuse the same SGs as the primary ENI
  security_groups = local.resolved_security_group_ids

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-vip"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
      Role        = "vip"
    }
  )
}
