resource "aws_eip" "public" {
  count  = var.assign_public_eip ? 1 : 0
  domain = "vpc"
  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-eip"
    environment = var.environment
    role        = "public"
  })
}

resource "aws_eip_association" "public" {
  count                = var.assign_public_eip ? 1 : 0
  allocation_id        = aws_eip.public[0].allocation_id
  network_interface_id = aws_network_interface.this.id

  # Wait until the instance is up to avoid IncorrectInstanceState
  depends_on = [aws_instance.this]
}






/*
########################################
# modules/ec2/eip_public.tf
########################################

resource "aws_eip" "public" {
  count  = var.assign_public_eip ? 1 : 0
  domain = "vpc"
  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-eip"
    environment = var.environment
    role        = "public"
  })
}

resource "aws_eip_association" "public" {
  count                = var.assign_public_eip ? 1 : 0
  allocation_id        = aws_eip.public[0].allocation_id
  network_interface_id = aws_network_interface.this.id

  # Wait for instance/ENI to be ready, prevents IncorrectInstanceState
  depends_on = [aws_instance.this]
}
*/
