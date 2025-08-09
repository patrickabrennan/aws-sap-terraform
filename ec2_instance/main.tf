module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = var.instances_to_create

  vpc_id            = data.aws_vpc.sap.id
  availability_zone = each.value.availability_zone

  aws_region       = var.aws_region
  environment      = var.environment
  hostname         = each.key
  domain           = each.value.domain
  private_ip       = try(each.value.private_ip, null)
  application_code = each.value.application_code
  application_SID  = each.value.application_SID
  ha               = each.value.ha
  ami_ID           = each.value.ami_ID
  #subnet_ID        = try(each.value.subnet_ID, "")
  instance_type    = each.value.instance_type

  hana_data_storage_type   = try(each.value.hana_data_storage_type, "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type, "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")

  custom_ebs_config = null # unless you want to pass it in per instance
  key_name          = each.value.key_name
  monitoring        = each.value.monitoring
  root_ebs_size     = tostring(each.value.root_ebs_size) # your module expects string
  ec2_tags          = each.value.ec2_tags
}
