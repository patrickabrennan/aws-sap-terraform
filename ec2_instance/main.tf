##############################
# main.tf (HA wrapper)
##############################

# Expand HA pairs:
# - Non-HA: single node (keeps original name)
# - HA:     <name>-a in ha_azs[0], <name>-b in ha_azs[1]
locals {
  expanded_instances = merge(
    {
      for name, cfg in var.instances_to_create :
      name => merge(cfg, {
        node              = "single"
        availability_zone = try(cfg.availability_zone, var.default_availability_zone)
      })
      if !try(cfg.ha, false)
    },
    {
      for name, cfg in var.instances_to_create :
      "${name}-a" => merge(cfg, {
        node              = "primary"
        availability_zone = var.ha_azs[0]
      })
      if try(cfg.ha, false)
    },
    {
      for name, cfg in var.instances_to_create :
      "${name}-b" => merge(cfg, {
        node              = "secondary"
        availability_zone = var.ha_azs[1]
      })
      if try(cfg.ha, false)
    }
  )
}

module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = local.expanded_instances

  # Your existing wiring
  vpc_id            = data.aws_vpc.sap.id
  availability_zone = each.value.availability_zone

  aws_region       = var.aws_region
  environment      = var.environment
  hostname         = each.key
  domain           = each.value.domain
  private_ip       = try(each.value.private_ip, null)

  application_code = each.value.application_code
  application_SID  = each.value.application_SID
  ha               = try(each.value.ha, false)

  ami_ID        = each.value.ami_ID
  instance_type = each.value.instance_type

  # Optional: if you pass specific subnets per node
  subnet_ID = try(each.value.subnet_ID, "")

  # HANA layout hints (module has defaults)
  hana_data_storage_type   = try(each.value.hana_data_storage_type, "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type, "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")

  custom_ebs_config = try(each.value.custom_ebs_config, [])

  key_name      = each.value.key_name
  monitoring    = try(each.value.monitoring, false)
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = each.value.ec2_tags
}



/*
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

  #custom_ebs_config = null # unless you want to pass it in per instance
  custom_ebs_config = try(each.value.custom_ebs_config, [])

  key_name          = each.value.key_name
  monitoring        = each.value.monitoring
  root_ebs_size     = tostring(each.value.root_ebs_size) # your module expects string
  ec2_tags          = each.value.ec2_tags
}
*/
