data "aws_caller_identity" "current" {}

data "aws_iam_policy" "permissions_boundary_policy" {
  count = var.permissions_boundary_arn != "" ? 1 : 0

  arn = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "iam_instance_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
