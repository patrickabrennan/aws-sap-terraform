module "parameters" {
  source = "../../../parameters"

  environment = var.environment
  aws_region  = var.aws_region

  params_to_create = {
    "security_group/${aws_security_group.this.name}/id" = {
      "value" = aws_security_group.this.id
    }
  }
}
