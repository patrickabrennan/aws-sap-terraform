############################################
# Instances workspace - root main.tf
############################################

# Create one EC2 stack per entry in instances_to_create
module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = local.effective_instances_to_create

  vpc_id = data.aws_vpc.sap.id

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
  ami_ID           = each.value.ami_ID
  instance_type    = each.value.instance_type

  # … plus the rest of your inputs (EBS, KMS, subnet selection, etc.)


  # --- EBS layout controls (per instance) ---
  hana_data_storage_type   = try(each.value.hana_data_storage_type, "")
  hana_logs_storage_type   = try(each.value.hana_logs_storage_type, "")
  hana_backup_storage_type = try(each.value.hana_backup_storage_type, "")
  hana_shared_storage_type = try(each.value.hana_shared_storage_type, "")

  custom_ebs_config = try(each.value.custom_ebs_config, [])

  # --- Access / tags ---
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = each.value.ec2_tags

  # --- VIP controls (optional; keep if using VIP ENIs/EIPs) ---
  enable_vip_eni = try(var.enable_vip_eni, false)
  enable_vip_eip = try(var.enable_vip_eip, false)
  vip_subnet_id  = try(var.vip_subnet_id, "")

  # --- Subnet auto-selection narrowing (NO hard-coded IDs) ---
  # Primary ENI (instance) selection hints
  subnet_tag_key        = try(var.subnet_tag_key, "")
  subnet_tag_value      = try(var.subnet_tag_value, "")
  subnet_name_wildcard  = try(var.subnet_name_wildcard, "")      # e.g. "*public*" or "*private*"
  subnet_selection_mode = try(var.subnet_selection_mode, "unique") # "unique" or "first"

  # VIP ENI selection hints
  vip_subnet_tag_key        = try(var.vip_subnet_tag_key, "")
  vip_subnet_tag_value      = try(var.vip_subnet_tag_value, "")
  vip_subnet_name_wildcard  = try(var.vip_subnet_name_wildcard, "")      # e.g. "*public*"
  vip_subnet_selection_mode = try(var.vip_subnet_selection_mode, "unique") # "unique" or "first"
}
