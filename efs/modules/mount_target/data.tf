data "aws_subnets" "selected" {
  filter {
    name   = "tag:${var.sap_discovery_tag}"
    values = ["*"]
  }
}

data "aws_ssm_parameter" "kms_for_efs" {
  name = "/${var.environment}/kms/efs/arn"
}
