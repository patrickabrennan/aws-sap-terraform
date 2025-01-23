resource "aws_iam_instance_profile" "profile" {
  name = var.name
  role = aws_iam_role.iam_role.name

  tags = merge({
    "Name" = var.name
    },
  var.tags)
}
