############################################
# Primary ENI for the instance
############################################

resource "aws_network_interface" "this" {
  # Subnet chosen by the resolver (from data.tf)
  subnet_id = local.subnet_id_effective

  # Only set a static IP if provided (avoid empty strings/whitespace)
  private_ips = (
    var.private_ip != null && trimspace(var.private_ip) != "" ?
    [var.private_ip] :
    null
  )

  # Security groups resolved in data.tf:
  #   - if var.security_group_ids non-empty -> use it
  #   - else HANA -> /<env>/security_group/db1/id
  #   - else NW   -> /<env>/security_group/app1/id
  security_groups = local.resolved_security_group_ids

  # HANA nodes typically need SDC disabled
  source_dest_check = var.application_code == "hana" ? false : true

  description = "${var.hostname}-primary-eni"

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

  # Ensure the subnet assertion ran first (from data.tf)
  depends_on = [null_resource.assert_single_subnet]

  lifecycle {
    # If anything goes wrong in SG resolution, fail early
    precondition {
      condition     = length(local.resolved_security_group_ids) > 0
      error_message = "No security groups resolved for ${var.hostname}. Provide var.security_group_ids or ensure SSM params exist: /${var.environment}/security_group/db1/id or /${var.environment}/security_group/app1/id."
    }

    # Create new ENI before destroying the old one when replacement is needed
    create_before_destroy = true
  }
}
















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
