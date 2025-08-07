#Comment out the below and replace with the following
#resource "aws_iam_role" "iam_role" {
#  name                 = var.name
#  assume_role_policy   = data.aws_iam_policy_document.iam_instance_trust.json
#  permissions_boundary = try(data.aws_iam_policy.permissions_boundary_policy[0].arn, null)

#  tags = var.tags
#}
resource "aws_iam_role" "iam_role" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy

  permissions_boundary = try(local.permissions_boundary_arn, null)

  tags = var.tags
}
#end adjustment



resource "aws_iam_role_policy_attachment" "policy_attchment" {
  for_each = toset(var.policies)

  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${each.value}"
}

resource "aws_iam_role_policy_attachment" "managed_policy_attchment" {
  for_each = toset(var.managed_policies)

  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}



