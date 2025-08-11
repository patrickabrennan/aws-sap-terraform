##############################
# main.tf (HA wrapper)
##############################

# Expand HA pairs:
# - Non-HA: single node (keeps original name)
# - HA:     <name>-a in ha_azs[0], <name>-b in ha_azs[1]
locals {
  ########################################
# Expand HA safely (false -> 1 node; true -> -a and -b)
########################################

locals {
  # Base map you already have:
  # var.instances_to_create = {
  #   sapd01db1 = { ha = true,  ... }
  #   sapd01cs  = { ha = false, ... }
  # }

  # One entry when ha=false (keep original key), two entries (-a, -b) when ha=true
  expanded_instances = merge(
    # Primary node (always present)
    {
      for name, cfg in var.instances_to_create :
      (cfg.ha ? "${name}-a" : name) => merge(cfg, {
        hostname          = (cfg.ha ? "${name}-a" : name)
        node_index        = 0
        node_suffix       = (cfg.ha ? "a" : "")
        availability_zone = try(
          cfg.availability_zone,
          length(var.ha_azs) > 0 ? var.ha_azs[0] : var.default_availability_zone
        )
      })
    },
    # Secondary node (only when ha=true)
    {
      for name, cfg in var.instances_to_create :
      "${name}-b" => merge(cfg, {
        hostname          = "${name}-b"
        node_index        = 1
        node_suffix       = "b"
        availability_zone = try(
          cfg.secondary_availability_zone,
          length(var.ha_azs) > 1 ? var.ha_azs[1] : var.default_availability_zone
        )
      }) if try(cfg.ha, false)
    }
  )
}

########################################
# Launch instances from the expanded map
########################################

module "ec2_instances" {
  for_each = local.expanded_instances
  source   = "./modules/ec2"

  # placement
  availability_zone = each.value.availability_zone

  # required basics you already pass
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

  # public SSH access via EIP on the primary ENI
  assign_public_eip = var.assign_public_eip
}

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
