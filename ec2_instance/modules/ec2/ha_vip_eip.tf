########################################
# VIP public EIP (module scope)
########################################

# Toggle-controlled EIP for the VIP ENI
resource "aws_eip" "vip" {
  count  = var.enable_vip_eni && var.enable_vip_eip ? 1 : 0
  domain = "vpc"

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-vip-eip"
    environment = var.environment
  })
}

resource "aws_eip_association" "vip" {
  count = var.enable_vip_eni && var.enable_vip_eip ? 1 : 0

  allocation_id        = aws_eip.vip[0].id
  network_interface_id = aws_network_interface.ha_vip[0].id
}
