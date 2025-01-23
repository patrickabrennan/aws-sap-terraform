resource "aws_iam_policy" "policy" {
  name   = var.name
  path   = "/"
  policy = local.iam_permission_policy_document

  tags = merge({
    "Name" = var.name,
    },
  var.tags)
}
