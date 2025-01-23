data "aws_ssm_parameter" "sgs_to_allow" {
  for_each = toset(var.sgs_to_allow)

  name = "/${var.environment}/efs/${each.value}/security_group/id"
}
