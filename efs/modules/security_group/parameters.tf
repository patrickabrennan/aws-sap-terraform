module "parameters" {
  source = "../../../parameters"

  aws_region  = var.aws_region
  environment = var.environment

  params_to_create = {
    "efs/${var.sg_name}/security_group/arn" = {
      "value" = aws_security_group.this.arn
    }
    "efs/${var.sg_name}/security_group/id" = {
      "value" = aws_security_group.this.id
    }
  }
}
