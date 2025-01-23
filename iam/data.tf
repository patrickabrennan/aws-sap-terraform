data "aws_ssm_parameter" "sap_efs_list" {
  name = "/${var.environment}/efs/sap/list"
}

data "aws_ssm_parameter" "sap_kms_arn_list" {
  name = "/${var.environment}/kms/sap/list"
}