resource "aws_security_group_rule" "this" {
  for_each = data.aws_ssm_parameter.sgs_to_allow

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = each.value.value
  source_security_group_id = var.sg_source
  description              = "Allow EFS communication"
}
