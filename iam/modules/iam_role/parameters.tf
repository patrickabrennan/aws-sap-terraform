module "parameters" {
  source = "../../../parameters"

  environment = var.environment
  aws_region  = var.aws_region

  params_to_create = {
    "iam/role/${lower(var.name)}/arn" = {
      "value" = aws_iam_role.iam_role.arn
    },
    "iam/role/instance-profile/${lower(var.name)}/arn" = {
      "value" = aws_iam_instance_profile.profile.arn
    }
    "iam/role/${lower(var.name)}/name" = {
      "value" = aws_iam_role.iam_role.name
    },
    "iam/role/instance-profile/${lower(var.name)}/name" = {
      "value" = aws_iam_instance_profile.profile.name
    }
  }
}
