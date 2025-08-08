module "kms" {
  source   = "./modules/kms"
  for_each = var.keys_to_create

  aws_region  = var.aws_region
  environment = var.environment

  target_service = each.key
  alias_name     = try(each.value["alias_name"], "kms-${var.environment}-${lower(each.key)}")
}
