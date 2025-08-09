module "ec2" {
  source   = "./modules/ec2"
  #comment out below and replace 
  #for_each = var.instances_to_create
  for_each = local.instances_to_create_normalized

  aws_region               = var.aws_region
  environment              = var.environment
  hostname                 = each.key
  private_ip               = each.value["private_ip"]
  domain                   = each.value["domain"]
  application_code         = each.value["application_code"]
  application_SID          = each.value["application_SID"]
  ha                       = each.value["ha"]
  ami_ID                   = each.value["ami_ID"]
  # commnet out and replace, but not sure why
  subnet_ID                = each.value["subnet_ID"]
  subnet_ID                = each.value["subnet_ID"]   # now guaranteed
  instance_type            = each.value["instance_type"]
  hana_data_storage_type   = try(each.value["hana_data_storage_type"], null)
  hana_logs_storage_type   = try(each.value["hana_logs_storage_type"], null)
  hana_backup_storage_type = try(each.value["hana_backup_storage_type"], null)
  hana_shared_storage_type = try(each.value["hana_shared_storage_type"], null)
  custom_ebs_config        = try(each.value["custom_ebs_config"], [])
  key_name                 = each.value["key_name"]
  monitoring               = each.value["monitoring"]
  root_ebs_size            = each.value["root_ebs_size"]
  ec2_tags                 = each.value["ec2_tags"]
}
