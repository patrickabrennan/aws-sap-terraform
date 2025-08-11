resource "aws_network_interface" "this" {
  subnet_id = data.aws_subnet.effective.id

  # If you prefer to allow optional static IP:
  dynamic "private_ips" {
    for_each = var.private_ip == null ? [] : [var.private_ip]
    content {
      # provider requires a list; Terraform 1.6+ supports private_ip on ENI resource; keep dynamic list for compat
    }
  }

  security_groups   = var.security_group_ids
  source_dest_check = lower(var.application_code) == "hana" ? false : true

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-eni0"
    environment = var.environment
  })
}







#resource "aws_network_interface" "this" {
#  subnet_id         = data.aws_subnet.effective.id
#  #subnet_id         = var.subnet_ID
#  private_ips       = var.private_ip == "" ? null : [var.private_ip]
#  security_groups   = [var.application_code == "hana" ? data.aws_ssm_parameter.ec2_hana_sg.value : data.aws_ssm_parameter.ec2_nw_sg.value]
#  source_dest_check = var.application_code == "hana" ? false : true

#  tags = {
#    Name        = var.hostname
#    environment = var.environment
#  }
#}
