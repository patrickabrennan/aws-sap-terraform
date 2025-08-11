############################################
# Optional SSM lookup for KMS key ARN
############################################

data "aws_ssm_parameter" "ebs_kms" {
  count = var.ebs_kms_ssm_path != "" ? 1 : 0
  name  = var.ebs_kms_ssm_path
}

# One place to decide the final KMS key ARN for this module
locals {
  kms_key_arn_effective = (
    var.kms_key_arn != ""
    ? var.kms_key_arn
    : (
        var.ebs_kms_ssm_path != ""
        ? try(data.aws_ssm_parameter.ebs_kms[0].value, "")
        : ""
      )
  )
}
