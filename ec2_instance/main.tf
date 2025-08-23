############################################
# Root main.tf — Stable primary, optional HA secondary
############################################
# Assumes data.tf defines:
#   - data.aws_vpc.sap
#   - local.azs_with_subnets  (list of AZs that actually have a subnet)
#   - local.subnet_id_by_az   (map AZ -> subnet id)
#   - null_resource.assert_two_azs (optional guard ensuring >= 2 AZs)
############################################

############################################
# Auto AZ assignment (no hardcoded values)
############################################
locals {
  names_sorted = sort(keys(var.instances_to_create))
  _azs         = local.azs_with_subnets
}

# Guard: ensure we actually have AZs
resource "null_resource" "assert_have_azs" {
  lifecycle {
    precondition {
      condition     = length(local._azs) > 0
      error_message = "No AZs available in local.azs_with_subnets. Check VPC/subnet filters in data.tf."
    }
  }
}

locals {
  # Deterministic base AZ per *primary* name
  base_az_for_name = {
    for idx, name in local.names_sorted :
    name => local._azs[idx % length(local._azs)]
  }

  # Primary AZ per name with optional explicit override (only if non-empty)
  primary_az_for_name = {
    for name, cfg in var.instances_to_create :
    name => (
      try(trim(cfg.availability_zone) != "", false)
      ? trim(cfg.availability_zone)
      : local.base_az_for_name[name]
    )
  }

  # Secondary AZ per name (next AZ, wrap-around) only when ha = true
  secondary_az_for_name = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => local._azs[(index(local.names_sorted, name) + 1) % length(local._azs)]
    if try(cfg.ha, false)
  }

  # Final AZ per expanded instance key
  az_for_instance = merge(
    { for name, _ in var.instances_to_create : name => local.primary_az_for_name[name] },
    local.secondary_az_for_name
  )

  # Diagnostics
  az_blanks = [for k, az in local.az_for_instance : k if !(try(trim(az) != "", false))]
  az_without_subnet = [
    for k, az in local.az_for_instance : k
    if try(trim(az) != "", false) && !(contains(keys(local.subnet_id_by_az), az))
  ]
}

# Guard: AZ must be non-empty for every expanded instance
resource "null_resource" "assert_all_instances_have_az" {
  depends_on = [null_resource.assert_have_azs]
  lifecycle {
    precondition {
      condition     = length(local.az_blanks) == 0
      error_message = "Some instances computed a blank availability_zone: ${join(", ", local.az_blanks)}. Check azs_with_subnets and instances_to_create."
    }
  }
}

# Guard: each chosen AZ must have a mapped subnet id
resource "null_resource" "assert_all_instances_have_subnet" {
  lifecycle {
    precondition {
      condition     = length(local.az_without_subnet) == 0
      error_message = "Some instances map to an AZ without a subnet id: ${join(", ", local.az_without_subnet)}. Check subnet_id_by_az in data.tf."
    }
  }
}

############################################
# EC2 instances — PRIMARY
############################################
module "ec2_instances_primary" {
  source   = "./modules/ec2"
  for_each = { for name, cfg in var.instances_to_create : name => cfg }

  depends_on = [
    null_resource.assert_have_azs,
    null_resource.assert_all_instances_have_az,
    null_resource.assert_all_instances_have_subnet,
    null_resource.assert_two_azs, # remove from this list if you didn’t define it in data.tf
  ]

  # Region/VPC
  aws_region = var.aws_region
  vpc_id     = data.aws_vpc.sap.id

  # Identity
  hostname         = try(each.value.hostname, each.key)
  domain           = each.value.domain
  application_code = each.value.application_code
  application_SID  = each.value.application_SID

  # Placement
  availability_zone = local.primary_az_for_name[each.key]
  subnet_ID         = local.subnet_id_by_az[local.primary_az_for_name[each.key]]

  # Required module inputs
  environment = var.environment
  ha          = try(each.value.ha, false)

  # EC2 basics
  ami_ID        = each.value.ami_ID
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = each.value.ec2_tags

  # Subnet filter hints (module only uses these if subnet_ID is empty)
  subnet_tag_key        = try(var.subnet_tag_key, "")
  subnet_tag_value      = try(var.subnet_tag_value, "")
  subnet_name_wildcard  = try(var.subnet_name_wildcard, "")
  subnet_selection_mode = try(var.subnet_selection_mode, "unique")

  # VIP options
  enable_vip_eni            = try(var.enable_vip_eni, false)
  enable_vip_eip            = try(var.enable_vip_eip, false)
  vip_subnet_id             = try(var.vip_subnet_id, "")
  vip_subnet_tag_key        = try(var.vip_subnet_tag_key, "")
  vip_subnet_tag_value      = try(var.vip_subnet_tag_value, "")
  vip_subnet_name_wildcard  = try(var.vip_subnet_name_wildcard, "")
  vip_subnet_selection_mode = try(var.vip_subnet_selection_mode, "unique")
}

############################################
# EC2 instances — SECONDARY (HA)
############################################
module "ec2_instances_secondary" {
  source = "./modules/ec2"
  for_each = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, { hostname = "${try(cfg.hostname, name)}-b" })
    if try(cfg.ha, false)
  }

  depends_on = [
    null_resource.assert_have_azs,
    null_resource.assert_all_instances_have_az,
    null_resource.assert_all_instances_have_subnet,
    null_resource.assert_two_azs, # remove from this list if you didn’t define it in data.tf
  ]

  # Region/VPC
  aws_region = var.aws_region
  vpc_id     = data.aws_vpc.sap.id

  # Identity
  hostname         = each.value.hostname
  domain           = each.value.domain
  application_code = each.value.application_code
  application_SID  = each.value.application_SID

  # Placement — next AZ (wrap) and its subnet
  availability_zone = local.secondary_az_for_name[each.key]
  subnet_ID         = local.subnet_id_by_az[local.secondary_az_for_name[each.key]]

  # Required module inputs
  environment = var.environment
  ha          = true

  # EC2 basics
  ami_ID        = each.value.ami_ID
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  root_ebs_size = tostring(each.value.root_ebs_size)
  ec2_tags      = each.value.ec2_tags

  # Subnet filter hints (module only uses these if subnet_ID is empty)
  subnet_tag_key        = try(var.subnet_tag_key, "")
  subnet_tag_value      = try(var.subnet_tag_value, "")
  subnet_name_wildcard  = try(var.subnet_name_wildcard, "")
  subnet_selection_mode = try(var.subnet_selection_mode, "unique")

  # VIP options
  enable_vip_eni            = try(var.enable_vip_eni, false)
  enable_vip_eip            = try(var.enable_vip_eip, false)
  vip_subnet_id             = try(var.vip_subnet_id, "")
  vip_subnet_tag_key        = try(var.vip_subnet_tag_key, "")
  vip_subnet_tag_value      = try(var.vip_subnet_tag_value, "")
  vip_subnet_name_wildcard  = try(var.vip_subnet_name_wildcard, "")
  vip_subnet_selection_mode = try(var.vip_subnet_selection_mode, "unique")
}
