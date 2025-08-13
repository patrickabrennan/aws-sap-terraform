########################################
# modules/ec2/ec2.tf
# EC2 instance that:
#  - Attaches the primary ENI from eni.tf
#  - Creates "inline" data volumes via ebs_block_device (delete_on_termination = true)
#  - Leaves "external" volumes to ebs.tf (separate EBS + attachments)
########################################

resource "aws_instance" "this" {
  ami           = var.ami_ID
  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = var.monitoring

  # Attach the ENI created in eni.tf
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this.id
  }

  # IAM instance profile name decided in data.tf (override > HA vs non-HA from SSM)
  iam_instance_profile = local.iam_instance_profile_name_effective

  # Root volume
  root_block_device {
    volume_size = tonumber(var.root_ebs_size)
    volume_type = "gp3"

    # Encrypt only when we actually have a KMS key; otherwise inherit the account default
    encrypted  = local.kms_key_arn_effective != "" ? true : null
    kms_key_id = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null
  }

  # ---------------------------------------------
  # Inline data volumes (deleted with the instance)
  # Provided by local.inline_disks from ebs.tf:
  #   names typically: usrsap, sapmnt, tmp, swap
  # ---------------------------------------------
  dynamic "ebs_block_device" {
    for_each = { for d in local.inline_disks : d.device => d }
    content {
      device_name = ebs_block_device.value.device
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type

      # Only set IOPS/throughput when > 0 (throughput allowed on gp3 only)
      iops       = ebs_block_device.value.iops > 0 ? ebs_block_device.value.iops : null
      throughput = (ebs_block_device.value.type == "gp3" && ebs_block_device.value.throughput > 0) ? ebs_block_device.value.throughput : null

      delete_on_termination = true

      # Encrypt only when we actually have a KMS key; otherwise inherit the account default
      encrypted  = local.kms_key_arn_effective != "" ? true : null
      kms_key_id = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null
    }
  }

  # Useful identifying tags
  tags = merge(var.ec2_tags, {
    Name         = var.hostname
    environment  = var.environment
    domain       = var.domain
    app_code     = var.application_code
    app_sid      = var.application_SID
    ha           = tostring(var.ha)
  })

  # Create the replacement instance before destroying the old one,
  # so external volume detaches (in ebs.tf) can happen cleanly.
  lifecycle {
    create_before_destroy = true
  }
}
