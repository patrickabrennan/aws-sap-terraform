locals {
  iam_permission_policy_document = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for statement in var.statements : {
        Action   = statement.actions,
        Effect   = statement.effect,
        Resource = statement.resources
      }
    ]
  })
}
