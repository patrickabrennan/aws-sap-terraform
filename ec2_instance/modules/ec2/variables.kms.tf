############################################
# KMS / encryption inputs (module scope)
############################################

# Pass a KMS key ARN directly to encrypt EBS (root + data).
# Leave empty to skip, or to use the SSM fallback below.
variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "Optional KMS Key ARN to encrypt root and data volumes."
}

# (Optional) If your key ARN is stored in SSM Parameter Store, put the path here.
# Example: "/${var.environment}/kms/ebs/arn"
# Leave empty to disable SSM lookup.
variable "ebs_kms_ssm_path" {
  type        = string
  default     = ""
  description = "Optional SSM parameter path that contains the KMS Key ARN (String)."
}
