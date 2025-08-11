module "ec2_instances" {
  for_each = local.expanded_instances
  source   = "./modules/ec2"

  # placement
  vpc_id            = var.vpc_id
  availability_zone = each.value.availability_zone

  # basics
  aws_region       = var.aws_region
  environment      = var.environment
  hostname         = each.value.hostname
  domain           = each.value.domain
  private_ip       = try(each.value.private_ip, null)
  application_code = each.value.application_code
  application_SID  = each.value.application_SID
  ha               = try(each.value.ha, false)
  ami_ID           = each.value.ami_ID
  instance_type    = each.value.instance_type

  # storage config
  hana_data_storage_type   = try(each.value.hana_data_storage_type, "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type, "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")
  custom_ebs_config        = try(each.value.custom_ebs_config, [])

  # access / misc
  key_name      = each.value.key_name
  monitoring    = try(each.value.monitoring, false)
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = try(each.value.ec2_tags, {})

  # public EIP per-instance primary ENI (for SSH)
  assign_public_eip = var.assign_public_eip

  # security groups per app role (from SSM)
  security_group_ids = (
    lower(each.value.application_code) == "hana"
    ? [data.aws_ssm_parameter.db1_sg.value]
    : [data.aws_ssm_parameter.app1_sg.value]
  )

  # Optional: pass a KMS key ARN for EBS encryption (else AWS-managed default)
  kms_key_arn = try(each.value.kms_key_arn, null)

  enable_vip_eni = var.enable_vip_eni
  vip_subnet_id  = var.vip_subnet_id
}





/*
########################################
# main.tf (module call)
########################################

module "ec2_instances" {
  for_each = local.expanded_instances
  source   = "./modules/ec2"

  # placement
  vpc_id            = data.aws_vpc.sap.id        # keep if your module expects it
  availability_zone = each.value.availability_zone

  # basics
  aws_region       = var.aws_region
  environment      = var.environment
  hostname         = each.value.hostname
  domain           = each.value.domain
  private_ip       = try(each.value.private_ip, null)
  application_code = each.value.application_code
  application_SID  = each.value.application_SID
  ha               = each.value.ha
  ami_ID           = each.value.ami_ID
  instance_type    = each.value.instance_type

  # storage config
  hana_data_storage_type   = try(each.value.hana_data_storage_type, "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type, "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")
  custom_ebs_config        = try(each.value.custom_ebs_config, [])

  # access / misc
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = each.value.ec2_tags

  # public EIP per instance primary ENI (for SSH)
  assign_public_eip = var.assign_public_eip
}
*/
