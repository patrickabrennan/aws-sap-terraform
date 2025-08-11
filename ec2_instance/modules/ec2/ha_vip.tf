########################################
# VIP ENI (module scope)
########################################

# When vip_subnet_id is not provided, find exactly one subnet in the VPC/AZ
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
}

locals {
  vip_subnet_id_effective = (
    var.vip_subnet_id != "" ? var.vip_subnet_id :
    (length(data.aws_subnets.vip_candidates) == 1 && length(data.aws_subnets.vip_candidates[0].ids) == 1
      ? data.aws_subnets.vip_candidates[0].ids[0]
      : ""
    )
  )
}

resource "null_resource" "assert_vip_subnet" {
  count = var.enable_vip_eni ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.vip_subnet_id_effective != ""
      error_message = "VIP ENI cannot be created: no unique subnet found in VPC ${var.vpc_id} / AZ ${var.availability_zone}. Set vip_subnet_id."
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

