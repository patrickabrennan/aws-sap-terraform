############################################################
# Floating VIP ENI per HA group (optional, same AZ/subnet only)
############################################################

locals {
  ha_groups = {
    for name, cfg in var.instances_to_create :
    name => cfg if try(cfg.ha, false)
  }
}

# Only query subnets when we need a fallback
data "aws_subnets" "vip_candidates" {
  count = var.enable_vip_eni && var.vip_subnet_id == "" ? 1 : 0
  filter { name = "vpc-id"; values = [var.vpc_id] }
}

# Compute a safe, effective subnet id ('' if none found)
locals {
  vip_candidates_ids       = var.enable_vip_eni && var.vip_subnet_id == "" ? try(data.aws_subnets.vip_candidates[0].ids, []) : []
  vip_subnet_id_effective  = var.vip_subnet_id != "" ? var.vip_subnet_id : (length(local.vip_candidates_ids) > 0 ? local.vip_candidates_ids[0] : "")
}

resource "aws_network_interface" "ha_vip" {
  for_each = var.enable_vip_eni ? local.ha_groups : {}

  subnet_id   = local.vip_subnet_id_effective
  private_ips = var.vip_private_ip != "" ? [var.vip_private_ip] : null

  # Use SG from SSM based on application type (HANA vs NW)
  security_groups = [
    lower(each.value.application_code) == "hana"
    ? data.aws_ssm_parameter.ec2_hana_sg.value
    : data.aws_ssm_parameter.ec2_nw_sg.value
  ]

  tags = merge(try(each.value.ec2_tags, {}), {
    Name        = "${each.key}-vip"
    environment = var.environment
    role        = "vip"
  })

  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = "VIP ENI cannot be created: no subnets found in VPC ${var.vpc_id}. Set vip_subnet_id to a valid subnet (same AZ as your HA nodes)."
    }
  }
}

output "ha_vip_eni_ids" {
  description = "VIP ENI IDs keyed by HA group name"
  value       = var.enable_vip_eni ? { for k, v in aws_network_interface.ha_vip : k => v.id } : {}
}
