module "iam_policies" {
  for_each = local.iam_combined_policies
  source   = "./modules/iam_policy"

  aws_region  = var.aws_region
  environment = var.environment

  name       = each.value[0]["name"]
  statements = each.value[0]["statements"]

  tags = local.tags
}

module "iam_roles" {
  for_each = var.iam_roles
  source   = "./modules/iam_role"

  aws_region  = var.aws_region
  environment = var.environment

  name                     = each.value["name"]
# added the following two lines:
  role_name                = each.value["name"]  # NEW
  assume_role_policy       = each.value["assume_role_policy"]  # NEW
  
  policies                 = each.value["policies"]
  managed_policies         = each.value["managed_policies"]
  #comment out and replace with line below:
  #permissions_boundary_arn = each.value["permissions_boundary_arn"]
  permissions_boundary_arn = lookup(each.value, "permissions_boundary_arn", null)

  tags = local.tags

  depends_on = [module.iam_policies]
}
