module "file_system" {
  source   = "./modules/efs"
  for_each = var.efs_to_create

  aws_region               = var.aws_region
  environment              = var.environment
  sid_filesystem_to_create = each.key
  sap_discovery_tag        = var.sap_discovery_tag
  access_point_info        = each.value["access_point_info"]

  tags = local.tags
}

module "security_group" {
  source   = "./modules/security_group"
  for_each = module.file_system

  aws_region  = var.aws_region
  environment = var.environment
  sg_name     = "${var.environment}_${each.key}"
  #add in below and comment out old vpc line
  vpc         = local.vpc_id
  #vpc         = data.aws_vpc.selected.id

  tags = merge(local.tags, {
    type   = "efs",
    Name   = "${var.environment}_${each.key}"
    efs_id = "${each.value.efs_id}"
  })
#should I have used this 
#tags        = merge(local.tags, {
#    efs_id = each.value.efs_id
#  })
}

module "mount_target" {
  source   = "./modules/mount_target"
  for_each = module.security_group

  aws_region        = var.aws_region
  environment       = var.environment
  sg_id             = ["${each.value.sg_id}"]
  efs_id            = each.value.sg_tags_all.efs_id
  sap_discovery_tag = var.sap_discovery_tag
}
