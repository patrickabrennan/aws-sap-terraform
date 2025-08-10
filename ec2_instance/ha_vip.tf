############################################################
# Floating VIP ENI per HA group (optional, same AZ/subnet only)
############################################################

# Pick only the HA groups from the ORIGINAL input map
locals {
  ha_groups = {
    for name, cfg in var.instances_to_create :
    name => cfg if try(cfg.ha, false)
  }
}

# Security group SSM parameters (reuse the same paths you use in the module)
data "aws_ssm_parameter" "ec2_hana_sg" {
  count = var.enable_vip_eni ? 1 : 0
  name  = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  count = var.enable_vip_eni ? 1 : 0
  name  = "/${var.environment}/security_group/app1/id"
}

# If no VIP subnet is specified, pick one subnet from the VPC
data "aws_subnets" "vip_candidates" {
  count = var.enable_vip_eni && var.vip_subnet_id == "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_network_interface" "ha_vip" {
  for_each = var.enable_vip_eni ? local.ha_groups : {}

  # WARNING: ENIs are not cross-AZ. Use the same-AZ subnet for both HA nodes
  subnet_id = var.vip_subnet_id != "" ?
    var.vip_subnet_id :
    data.aws_subnets.vip_candidates[0].ids[0]

  private_ips = var.vip_private_ip != "" ? [var.vip_private_ip] : null

  security_groups = [
    lower(each.value.application_code) == "hana"
    ? data.aws_ssm_parameter.ec2_hana_sg[0].value
    : data.aws_ssm_parameter.ec2_nw_sg[0].value
  ]

  tags = merge(try(each.value.ec2_tags, {}), {
    Name        = "${each.key}-vip"
    environment = var.environment
    role        = "vip"
  })
}

output "ha_vip_eni_ids" {
  description = "VIP ENI IDs keyed by HA group name"
  value       = var.enable_vip_eni ? { for k, v in aws_network_interface.ha_vip : k => v.id } : {}
}
