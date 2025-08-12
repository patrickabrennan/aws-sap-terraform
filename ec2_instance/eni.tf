resource "aws_network_interface" "this" {
  subnet_id         = data.aws_subnet.effective.id
  description       = "${var.hostname}-eni"
  source_dest_check = var.application_code == "hana" ? false : true

  # Only send SGs when we actually have at least one. Avoid [] which triggers AWS error.
  security_groups = length(local.resolved_security_group_ids) > 0
    ? local.resolved_security_group_ids
    : null

  # Only send a static IP if you set one
  private_ips = (var.private_ip != null && var.private_ip != "")
    ? [var.private_ip]
    : null

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-eni"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
    }
  )

  depends_on = [
    null_resource.assert_single_subnet,
    null_resource.assert_sg_nonempty
  ]
}
