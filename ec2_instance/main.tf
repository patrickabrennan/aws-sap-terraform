############################################
# Root main.tf — Stable primary, optional HA secondary
############################################

# Assumes you already have:
# - data.tf that resolves data.aws_vpc.sap
# - variables.tf declaring the root variables you already use
# - modules/ec2 module that accepts these arguments

############################################
# Auto AZ assignment (no hardcoded values)
############################################

#added 8/22/2025
locals {
  names_sorted = sort(keys(var.instances_to_create))
  _azs = local.azs_with_subnets

  primaries = {
    for name, cfg in var.instances_to_create :
    name => merge(cfg, {
      hostname          = try(cfg.hostname, name)
      availability_zone = try(cfg.availability_zone, local._azs[index(local.names_sorted, name) % length(local._azs)])
      ha                = try(cfg.ha, false)
    })
  }

  secondaries = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, {
      hostname          = "${try(cfg.hostname, name)}-b"
      availability_zone = local._azs[(index(local.names_sorted, name) + 1) % length(local._azs)]
      ha                = true
    })
    if try(cfg.ha, false)
  }

  all_instances = merge(local.primaries, local.secondaries)
}

#commented out 8/22/2025
/*
locals {
  # stable order for determinism
  names_sorted = sort(keys(var.instances_to_create))

  # Primary instances: AZ determined by index % AZ count
  primaries = {
    for name, cfg in var.instances_to_create :
    name => merge(cfg, {
      hostname          = try(cfg.hostname, name)
      availability_zone = try(cfg.availability_zone, local.azs_sorted[index(local.names_sorted, name) % length(local.azs_sorted)])
      ha                = try(cfg.ha, false)
    })
  }

  # HA secondaries: next AZ (wrap) if ha = true
  secondaries = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, {
      hostname          = "${try(cfg.hostname, name)}-b"
      availability_zone = local.azs_sorted[(index(local.names_sorted, name) + 1) % length(local.azs_sorted)]
      ha                = true
    })
    if try(cfg.ha, false)
  }

  all_instances = merge(local.primaries, local.secondaries)
}
*/





#commented out on 8/21/205
/*
locals {
  # Simple AZ sibling map (adjust if you use different AZs)
  az_sibling_map = {
    "us-east-1a" = "us-east-1b"
    "us-east-1b" = "us-east-1a"
    # add more if needed
  }

  # Always create one PRIMARY per entry; stable key == entry name (no "-a")
  primaries = {
    for name, cfg in var.instances_to_create :
    name => merge(cfg, {
      hostname          = name
      availability_zone = cfg.availability_zone
      ha                = try(cfg.ha, false)
    })
  }

  # Only create a SECONDARY when ha=true; key == "<name>-b"
  # Secondary AZ: pick sibling of the primary AZ (or fall back to same if unknown)
  secondaries = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, {
      hostname          = "${name}-b"
      availability_zone = lookup(local.az_sibling_map, cfg.availability_zone, cfg.availability_zone)
      ha                = true
    })
    if try(cfg.ha, false)
  }

  # Final set of nodes to create
  nodes = merge(local.primaries, local.secondaries)
}
*/
#end comment out on 8/21/2025






module "ec2_instances" {
  source   = "./modules/ec2"        # <-- keep your path
  for_each = local.all_instances     # 1) iterate over expanded set (primary + HA)

  # NEW: satisfy required module inputs
  environment = var.environment              # <-- string like "dev", already in your workspace
  ha          = try(each.value.ha, false)    # <-- per-instance HA flag (bool)

  # Region/VPC
  aws_region = var.aws_region
  vpc_id     = data.aws_vpc.sap.id

  # Identity per node
  hostname         = each.value.hostname
  domain           = each.value.domain
  application_code = each.value.application_code
  application_SID  = each.value.application_SID

  # 2) NEW: computed, not hard-coded
  availability_zone = each.value.availability_zone
  subnet_ID         = try(each.value.subnet_ID, local.subnet_id_by_az[each.value.availability_zone])

  # Existing inputs (unchanged)
  ami_ID        = each.value.ami_ID
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring

  # If your module's variable type for root_ebs_size is number, you can pass it directly.
  # If it's string, keep tostring(). Match your module's var type.
  root_ebs_size = tostring(each.value.root_ebs_size)

  ec2_tags = each.value.ec2_tags

  # Keep these filters if your module uses them; when subnet_ID is set, the module will prefer it.
  subnet_tag_key        = try(var.subnet_tag_key, "")
  subnet_tag_value      = try(var.subnet_tag_value, "")
  subnet_name_wildcard  = try(var.subnet_name_wildcard, "")
  subnet_selection_mode = try(var.subnet_selection_mode, "unique")

  # VIP options (only if your module defines them)
  enable_vip_eni            = try(var.enable_vip_eni, false)
  enable_vip_eip            = try(var.enable_vip_eip, false)
  vip_subnet_id             = try(var.vip_subnet_id, "")
  vip_subnet_tag_key        = try(var.vip_subnet_tag_key, "")
  vip_subnet_tag_value      = try(var.vip_subnet_tag_value, "")
  vip_subnet_name_wildcard  = try(var.vip_subnet_name_wildcard, "")
  vip_subnet_selection_mode = try(var.vip_subnet_selection_mode, "unique")
}



# Commnet out 8-21-2025
/*
module "ec2_instances" {
  for_each = local.nodes
  source   = "./modules/ec2"

  # Core / environment
  aws_region  = var.aws_region
  environment = var.environment
  vpc_id      = data.aws_vpc.sap.id

  # Identity per node
  hostname          = each.value.hostname
  domain            = each.value.domain
  application_code  = each.value.application_code
  application_SID   = each.value.application_SID
  availability_zone = each.value.availability_zone
  ha                = each.value.ha

  # EC2 basics
  ami_ID        = each.value.ami_ID
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  root_ebs_size = each.value.root_ebs_size
  ec2_tags      = try(each.value.ec2_tags, {})

  # Optional private IP / explicit subnet (module already supports "")
  private_ip = try(each.value.private_ip, null)
  subnet_ID  = try(each.value.subnet_ID, "")

  # EBS layout knobs (pass-through; module will default if "")
  hana_data_storage_type   = try(each.value.hana_data_storage_type,   "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type,   "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")
  custom_ebs_config        = try(each.value.custom_ebs_config, [])

  # KMS / encryption
  kms_key_arn      = try(var.kms_key_arn, "")
  ebs_kms_ssm_path = try(var.ebs_kms_ssm_path, "")

  # Subnet selection (primary ENI) — keeps your “no hardcoding” behavior
  subnet_tag_key       = try(var.subnet_tag_key, "")
  subnet_tag_value     = try(var.subnet_tag_value, "")
  subnet_name_wildcard = try(var.subnet_name_wildcard, "")
  subnet_selection_mode = try(var.subnet_selection_mode, "unique") # or "first"

  # VIP ENI/EIP (optional, per-node behavior is unchanged)
  enable_vip_eni            = try(var.enable_vip_eni, false)
  enable_vip_eip            = try(var.enable_vip_eip, false)
  vip_subnet_id             = try(var.vip_subnet_id, "")
  vip_subnet_tag_key        = try(var.vip_subnet_tag_key, "")
  vip_subnet_tag_value      = try(var.vip_subnet_tag_value, "")
  vip_subnet_name_wildcard  = try(var.vip_subnet_name_wildcard, "")
  vip_subnet_selection_mode = try(var.vip_subnet_selection_mode, "unique") # or "first"
}
*/
#end comment out on 8/21/2025
