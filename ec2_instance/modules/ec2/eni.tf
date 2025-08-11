# Primary ENI (keep ENI here; do NOT also define it in ec2.tf)
resource "aws_network_interface" "this" {
  subnet_id         = data.aws_subnet.effective.id
  security_groups   = var.security_group_ids
  source_dest_check = lower(var.application_code) == "hana" ? false : true

  # (Optional static IP support)
  # If you want to force a specific IP, uncomment the next line.
  # private_ips = var.private_ip == null ? null : [var.private_ip]

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
