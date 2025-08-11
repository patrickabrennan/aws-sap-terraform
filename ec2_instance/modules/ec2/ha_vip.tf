############################################
# Subnet discovery for VIP ENI (optional)
############################################

# Only query when VIP is enabled AND no explicit vip_subnet_id was given
data "aws_subnets" "vip" {
  count = (var.enable_vip_eni && var.vip_subnet_id == "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Keep VIP ENI in the instance AZ by default
  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional: tag key/value
  dynamic "filter" {
    for_each = (var.vip_subnet_tag_key != "" && var.vip_subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.vip_subnet_tag_key}"
      values = [var.vip_subnet_tag_value]
    }
  }

  # Optional: tag:Name wildcard
  dynamic "filter" {
    for_each = var.vip_subnet_name_wildcard != "" ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vip_subnet_name_wildcard]
    }
  }
}

locals {
  vip_candidates = var.enable_vip_eni
    ? (var.vip_subnet_id != "" ? [var.vip_subnet_id] : try(data.aws_subnets.vip[0].ids, []))
    : []

  vip_subnet_id_effective = !var.enable_vip_eni
    ? ""
    : (
        length(local.vip_candidates) == 1
          ? local.vip_candidates[0]
          : (
              length(local.vip_candidates) > 1 && var.vip_subnet_selection_mode == "first"
                ? sort(local.vip_candidates)[0]
                : ""
            )
      )
}

# Helpful assertion when VIP is enabled but subnet can't be uniquely determined
resource "null_resource" "assert_vip_subnet" {
  count    = var.enable_vip_eni ? 1 : 0
  triggers = { chosen = local.vip_subnet_id_effective }

  lifecycle {
    precondition {
      condition = local.vip_subnet_id_effective != ""
      error_message = "VIP ENI cannot be created: no single subnet found in ${var.vpc_id} / ${var.availability_zone}.\n" \
        "Refine selection by setting one of:\n" \
        " - vip_subnet_tag_key + vip_subnet_tag_value\n" \
        " - vip_subnet_name_wildcard (e.g., \"*public*\" or \"*private*\")\n" \
        "Or allow auto-pick by setting:\n" \
        " - vip_subnet_selection_mode = \"first\""
    }
  }
}

# (Optional) If you create the VIP ENI here, you can use local.vip_subnet_id_effective:
# resource "aws_network_interface" "ha_vip" {
#   count     = var.enable_vip_eni ? 1 : 0
#   subnet_id = local.vip_subnet_id_effective
#   description = "HA VIP ENI"
#   tags = { Name = "${var.availability_zone}-vip" }
# }
