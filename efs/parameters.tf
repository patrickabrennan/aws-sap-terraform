module "parameters" {
  source = "../parameters"

  environment = var.environment
  aws_region  = var.aws_region

  params_to_create = {
    "efs/sap/list" = {
      "value" = jsonencode([for k, v in module.file_system : v.arn])
    }
  }
}
