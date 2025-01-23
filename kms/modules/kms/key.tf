resource "aws_kms_key" "this" {
  description             = "KMS key for ${var.target_service}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}
