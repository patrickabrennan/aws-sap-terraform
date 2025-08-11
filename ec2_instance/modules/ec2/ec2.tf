########################################
# modules/ec2/ec2.tf
# EC2 instance using the ENI from eni.tf
########################################

resource "aws_instance" "this" {
  ami           = var.ami_ID
  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = var.monitoring

  # attach the ENI created in eni.tf
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this.id
  }

  # IAM instance profile (string name from SSM in data.tf)
  iam_instance_profile = (
    var.ha
    ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
    : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
  )

  root_block_device {
    volume_size = tonumber(var.root_ebs_size)
    volume_type = "gp3"
    encrypted  = local.kms_key_arn_effective != "" ? true : null
    kms_key_id = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null

    #encrypted   = true
    #kms_key_id  = var.kms_key_arn
  }

  tags = merge(var.ec2_tags, {
    Name         = var.hostname
    environment  = var.environment
    domain       = var.domain
    app_code     = var.application_code
    app_sid      = var.application_SID
    ha           = tostring(var.ha)
  })

  lifecycle {
    create_before_destroy = true
  }
}
