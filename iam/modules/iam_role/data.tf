data "aws_caller_identity" "current" {}

#Comment this out and replace with the below
#data "aws_iam_policy" "permissions_boundary_policy" {
#  count = var.permissions_boundary_arn != "" ? 1 : 0

#  arn = var.permissions_boundary_arn
#}
data "aws_iam_policy" "permissions_boundary_policy" {
  count = var.attach_permissions_boundary ? 1 : 0
  arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/example-permissions-boundary-rds"
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

