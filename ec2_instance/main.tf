############################################
# Root main.tf — Stable primary, optional HA secondary
############################################

############################################
# Auto AZ assignment (no hardcoded values)
############################################
locals {
  # Stable ordering of the input map keys
  names_sorted = sort(keys(var.instances_to_create))

  # Only AZs that truly have subnets (built in data.tf)
  _azs = local.azs_with_subnets
}

# Guard: ensure we actually have at least one AZ (data.tf can add a stricter >=2 guard)
resource "null_resource" "assert_have_azs" {
  lifecycle {
    precondition {
      condition     = length(local._azs) > 0
      error_message = "No AZs available in local.azs_with_subnets. Check VPC/subnet filters in data.tf."
    }
  }
}

locals {
  # Deterministic base AZ per *primary* name (does not depend on any unknowns)
  base_az_for_name = {
    for idx, name in local.names_sorted :
    name => local._azs[idx % length(local._azs)]
  }

  # Primary AZ per name with optional explicit override (only if non-empty string)
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

  # Final AZ per expanded instance key (never null/empty)
  az_for_instance = merge(
    # Primaries use the (possibly-overridden) primary_az_for_name
    {
      for name, _ in var.instances_to_create :
      name => local.primary_az_for_name[name]
    },
    # Secondaries use next-AZ mapping
    local.secondary_az_for_name
  )

  # Diagnostics
  az_blanks = [
    for k, az in local.az_for_instance : k
    if !(try(trim(az) != "", false))
  ]

  az_without_subnet = [
    for k, az in local.az_for_instance : k
    if try(trim(az) != "", false) && !(contains(keys(local.subnet_id_by_az), az))
  ]
}

# Guard: make sure every expanded instance ended up with a non-empty AZ
resource "null_resource" "assert_all_instances_have_az" {
  depends_on = [null_resource.assert_have_azs]
  lifecycle {
    precondition {
      condition     = length(local.az_blanks) == 0
      error_message = "Some instances computed a blank availability_zone: ${join(", ", local.az_blanks)}. Check azs_with_subnets and instances_to_create."
    }
  }
}

# Guard: ensure every chosen AZ has a mapped subnet id
resource "null_resource" "assert_all_instances_have_subnet" {
  lifecycle {
    precondition {
      condition     = length(local.az_without_subnet) == 0
      error_message = "Some instances map to an AZ without a subnet id: ${join(", ", local.az_without_subnet)}. Check subnet_id_by_az in data.tf."
    }
  }
}

############################################
# EC2 instances (primary + optional HA secondary)
############################################
module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = var.instances_to_create
    # we’ll expand HA here to keep keys simple below
}

# Expand to primary + optional secondary with explicit AZ and subnet selection
module "ec2_instances_primary" {
  source   = "./modules/ec2"
  for_each = { for name, cfg in var.instances_to_create : name => cfg }

  depends_on = [
    null_resource.assert_have_azs,
    null_resource.assert_all_instances_have_az,
    null_resource.assert_all_instances_have_subnet,
    null_resource.assert_two_azs
  ]

  # Region/VPC
  aws_region = var.aws_region
  vpc_id     = data.aws_vpc.sap.id

  # Identity
  hostname         = try(each.value.hostname, each.key)
  domain           = each.value.domain
  application_code = each.value.application_code
  application_SID  = each.value.application_SID

  # Placement — use guarded AZ and per-AZ subnet map
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
    null_resource.assert_two_azs
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
