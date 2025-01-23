data "aws_ssm_parameter" "kms_for_efs" {
  name = "/${var.environment}/kms/efs/arn"
}
