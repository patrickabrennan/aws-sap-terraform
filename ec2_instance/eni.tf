resource "aws_network_interface" "this" {
  subnet_id = var.subnet_ID

  # Only set this if provided; null means "omit" and AWS will assign one.
  private_ips = var.private_ip == null ? null : [var.private_ip]

  security_groups   = [var.application_code == "hana" ? data.aws_ssm_parameter.ec2_hana_sg.value : data.aws_ssm_parameter.ec2_nw_sg.value]
  source_dest_check = var.application_code == "hana" ? false : true

  tags = {
    Name = var.hostname
  }
}
