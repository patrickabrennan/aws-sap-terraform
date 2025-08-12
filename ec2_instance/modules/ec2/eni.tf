############################################
# Primary ENI for the instance
############################################

resource "aws_network_interface" "this" {
  subnet_id         = data.aws_subnet.effective.id
  description       = "${var.hostname}-primary"
  source_dest_check = true

  # Optional static private IP, else AWS assigns one
  dynamic "private_ips" {
    for_each = var.private_ip != null && trim(var.private_ip) != "" ? [1] : []
    content  = [var.private_ip]
  }

  # Resolved SGs from data.tf locals
  security_groups = local.resolved_security_group_ids

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-eni"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
      Role        = "primary-eni"
    }
  )
}
