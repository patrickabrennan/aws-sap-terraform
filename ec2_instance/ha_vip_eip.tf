############################################################
# Public IPs for VIP ENIs (Elastic IP association)
############################################################

# One EIP per VIP ENI (only when both VIP ENIs and EIPs are enabled)
resource "aws_eip" "vip" {
  for_each = var.enable_vip_eni && var.enable_vip_eip ? aws_network_interface.ha_vip : {}

  domain = "vpc"  # VPC-style EIP
  tags = {
    Name        = "${each.key}-vip-eip"
    environment = var.environment
    role        = "vip"
  }
}

resource "aws_eip_association" "vip" {
  for_each = var.enable_vip_eni && var.enable_vip_eip ? aws_network_interface.ha_vip : {}

  allocation_id        = aws_eip.vip[each.key].allocation_id
  network_interface_id = aws_network_interface.ha_vip[each.key].id
  private_ip_address   = aws_network_interface.ha_vip[each.key].private_ips[0]
}

output "ha_vip_public_ips" {
  description = "Public EIPs mapped by HA group"
  value       = var.enable_vip_eni && var.enable_vip_eip ? { for k, _ in aws_eip.vip : k => aws_eip.vip[k].public_ip } : {}
}
