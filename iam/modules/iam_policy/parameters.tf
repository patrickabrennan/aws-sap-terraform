module "parameters" {
  source = "../../../parameters"

  environment = var.environment
  aws_region  = var.aws_region

  params_to_create = {
    "iam/policy/${lower(var.name)}/arn" = {
      "value" = aws_iam_policy.policy.arn
    },
  }
}
