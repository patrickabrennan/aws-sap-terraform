module "parameters" {
  source = "../parameters"

  environment = var.environment
  aws_region  = var.aws_region

  params_to_create = {
    "kms/sap/list" = {
      "value" = jsonencode([for k, v in module.kms : v.arn])
    }
  }
}
