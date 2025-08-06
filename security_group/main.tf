module "app_security_groups" {
  for_each = var.app_sg_list
  source   = "./modules/security_group"

  environment = var.environment
  aws_region  = var.aws_region
  #vpc_id      = data.aws_vpc.selected.id
  vpc_id = var.vpc_id

  name         = each.key
  description  = each.value["description"]
  rules        = each.value["rules"]
  efs_to_allow = each.value["efs_to_allow"]

  tags = local.tags
}

module "db_security_groups" {
  for_each = var.db_sg_list
  source   = "./modules/security_group"

  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = data.aws_vpc.selected.id

  name                       = each.key
  description                = each.value["description"]
  rules                      = each.value["rules"]
  efs_to_allow               = each.value["efs_to_allow"]
  dependency_security_groups = module.app_security_groups

  tags = local.tags
}

module "additional_rules_for_efs" {
  for_each = merge(module.app_security_groups, module.db_security_groups)
  source   = "./modules/additional_rules_for_existing_sg"

  environment  = var.environment
  sgs_to_allow = each.value.efs_to_allow
  sg_source    = each.value.sg_id
}

