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

  # (NO iam_instance_profile here)

  root_block_device {
    volume_size = tonumber(var.root_ebs_size)
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_arn
  }

  tags = merge(var.ec2_tags, {
    Name        = var.hostname
    environment = var.environment
    domain      = var.domain
    app_code    = var.application_code
    app_sid     = var.application_SID
    ha          = tostring(var.ha)
  })

  lifecycle {
    create_before_destroy = true
  }
}









/*
resource "aws_instance" "this" {
  ami           = var.ami_ID
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring = var.monitoring

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this.id
  }

  root_block_device {
    volume_size = tonumber(var.root_ebs_size)
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_arn
  }

  tags = merge(var.ec2_tags, {
    Name        = var.hostname
    environment = var.environment
    domain      = var.domain
    app_code    = var.application_code
    app_sid     = var.application_SID
    ha          = tostring(var.ha)
  })

  lifecycle {
    create_before_destroy = true
  }
}
*/




/*
resource "aws_instance" "this" {
  ami                     = var.ami_ID
  instance_type           = var.instance_type
  key_name                = var.key_name
  monitoring              = var.monitoring
  ebs_optimized           = true
  disable_api_termination = true

  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }

  tags = {
    Name    = var.hostname
    AppCode = var.application_code
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_ssm_parameter.ebs_kms.value
    volume_size           = var.root_ebs_size
    volume_type           = "gp3"
    tags = {
      Name       = "${var.hostname}-root"
      MountPoint = "/"
    }

  }
*/

  iam_instance_profile = var.ha == true ? data.aws_ssm_parameter.ec2_ha_instance_profile.value : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value

}
