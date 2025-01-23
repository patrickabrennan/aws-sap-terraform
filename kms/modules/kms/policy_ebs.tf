resource "aws_kms_key_policy" "ebs_policy" {
  count = lower(var.target_service) == "ebs" ? 1 : 0

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
      },
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }

        Resource = "*"
        Sid      = "Allow autoscaling to use the EBS custom KMS key"
      },
      {
        Action = "kms:CreateGrant"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }

        Resource = "*"
        Sid      = "Allow autoscaling to use the EBS custom KMS key"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
    Version = "2012-10-17"
  })
}
