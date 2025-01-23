resource "aws_kms_key_policy" "general_policy" {
  count = lower(var.target_service) != "ebs" ? 1 : 0

  key_id = aws_kms_key.this.id
  policy = jsonencode({
    Id = "Policy"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Resource = "*"
        Sid      = "Enable root access"
      }
    ]
    Version = "2012-10-17"
  })
}
