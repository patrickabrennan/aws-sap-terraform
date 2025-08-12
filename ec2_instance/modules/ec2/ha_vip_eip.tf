############################################
# Public EIP for the VIP ENI (optional)
############################################

# Allocate an EIP only if VIP ENI is enabled AND user wants a public IP for it
resource "aws_eip" "vip" {
  count  = (var.enable_vip_eni && var.enable_vip_eip) ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-vip-eip"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
    }
  )
}

# Associate the EIP to the VIP ENI created in ha_vip.tf
resource "aws_eip_association" "vip" {
  count = (var.enable_vip_eni && var.enable_vip_eip) ? 1 : 0

  network_interface_id = aws_network_interface.ha_vip[0].id
  allocation_id        = aws_eip.vip[0].id

  depends_on = [
    aws_network_interface.ha_vip
  ]
}
