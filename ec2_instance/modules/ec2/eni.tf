############################################
# Primary ENI for the instance
############################################

resource "aws_network_interface" "this" {
  subnet_id       = local.subnet_id_effective
  security_groups = local.resolved_security_group_ids

  private_ips = (
    var.private_ip != null && var.private_ip != "" ? [var.private_ip] : null
  )

  description       = "${var.hostname}-primary"
  source_dest_check = true

  tags = merge(
    var.ec2_tags,
    {
      Name        = var.hostname
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
    }
  )

  # Ensure subnet selection guard ran
  depends_on = [null_resource.assert_single_subnet]

  # Keep ENI stable (prevents primary churn)
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      security_groups,
      private_ips,
      subnet_id,
      description
    ]
  }
}













/*
############################################
# Primary ENI for the instance
############################################

resource "aws_network_interface" "this" {
  subnet_id         = local.subnet_id_effective
  security_groups   = local.resolved_security_group_ids

  # only set a static IP if provided
  private_ips       = (var.private_ip != null && var.private_ip != "") ? [var.private_ip] : null

  description       = "${var.hostname}-primary"
  source_dest_check = true

  tags = merge(
    var.ec2_tags,
    {
      Name        = var.hostname
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
    }
  )

  # ensure the subnet assertion ran first
  depends_on = [null_resource.assert_single_subnet]
}
*/








############################################
# Primary ENI for the instance
############################################

#resource "aws_network_interface" "this" {
#  subnet_id         = local.subnet_id_effective
#  security_groups   = local.resolved_security_group_ids

#  # only set a static IP if provided
#  private_ips       = (var.private_ip != null && var.private_ip != "") ? [var.private_ip] : null

#  description       = "${var.hostname}-primary"
#  source_dest_check = true

#  tags = merge(
#    var.ec2_tags,
#    {
#      Name        = var.hostname
#      Environment = var.environment
#      Application = var.application_code
#      Hostname    = var.hostname
#    }
#  )

#  # ensure the subnet assertion ran first
#  depends_on = [null_resource.assert_single_subnet]
#}
