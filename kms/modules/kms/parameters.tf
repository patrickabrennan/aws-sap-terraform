module "parameters" {
  source = "../../../parameters"

  aws_region  = var.aws_region
  environment = var.environment

  params_to_create = {
    "kms/${lower(var.target_service)}/arn" = {
      "value" = aws_kms_key.this.arn
    },
    "kms/${lower(var.target_service)}/alias" = {
      "value" = aws_kms_alias.this.name
    }
  }
}
