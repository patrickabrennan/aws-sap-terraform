############################################
# VIP subnet resolution (no AZ input)
# - Select VIP candidate subnets by VPC + tags/Name
# - Then constrain to the instance's AZ (so the ENI can attach)
############################################

# Candidate VIP subnets by VPC + optional tag/name
data "aws_subnets" "vip_filters" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
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
  # Pool: explicit ID (if any) + filtered list (when enabled)
  _vip_ids_raw = concat(
    (var.vip_subnet_id != "" ? [var.vip_subnet_id] : []),
    (var.enable_vip_eni ? try(data.aws_subnets.vip_filters[0].ids, []) : [])
  )
  _vip_ids_clean = [for id in local._vip_ids_raw : id if id != null && trim(id, " ") != ""]
}

# Fetch AZ metadata for each VIP candidate to match the instance AZ
data "aws_subnet" "vip_meta" {
  for_each = var.enable_vip_eni ? toset(local._vip_ids_clean) : []
  id       = each.value
}

locals {
  # Keep only VIP subnets that share the instance's AZ (from data.tf)
  _vip_same_az_ids = [
    for s in data.aws_subnet.vip_meta : s.id
    if try(s.availability_zone, "") == local.instance_az_effective
  ]

  _vip_pool = length(local._vip_same_az_ids) > 0 ? local._vip_same_az_ids : []

  vip_need_unique = var.vip_subnet_selection_mode != "first"
  vip_subnet_id_effective = (
    length(local._vip_pool) == 0
      ? local.primary_subnet_id  # fallback to the primary subnet (same AZ by definition)
      : (
          local.vip_need_unique
            ? (length(local._vip_pool) == 1 ? local._vip_pool[0] : "")
            : sort(local._vip_pool)[0]
        )
  )
}

# Enforce: only when VIP is enabled
resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = <<-EOT
        VIP ENI cannot be created: no suitable subnet found in ${var.vpc_id} sharing AZ ${local.instance_az_effective}.
        Narrow selection with:
          - vip_subnet_tag_key + vip_subnet_tag_value
          - vip_subnet_name_wildcard (e.g., "*public*" or "*private*")
        Or auto-pick by setting:
          - vip_subnet_selection_mode = "first"
      EOT
    }
  }
}

# VIP ENI in the chosen subnet (same AZ as the instance)
resource "aws_network_interface" "ha_vip" {
  count = var.enable_vip_eni ? 1 : 0

  subnet_id         = local.vip_subnet_id_effective
  description       = "${var.hostname}-vip"
  source_dest_check = var.application_code == "hana" ? false : true

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
