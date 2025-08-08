resource "aws_ssm_parameter" "parameters" {
  for_each = var.params_to_create

  name  = "/${var.environment}/${each.key}"
  type  = "SecureString"
  value = each.value["value"]
  #added the line below:
  overwrite = true
}
