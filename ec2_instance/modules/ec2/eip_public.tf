# Allocate one EIP per instance when enabled
resource "aws_eip" "public" {
  count  = var.assign_public_eip ? 1 : 0
  domain = "vpc"
  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-eip"
    environment = var.environment
    role        = "public"
  })
}

# Associate that EIP to the instance's primary ENI
resource "aws_eip_association" "public" {
  count                = var.assign_public_eip ? 1 : 0
  allocation_id        = aws_eip.public[0].allocation_id
  network_interface_id = aws_network_interface.this.id
}
