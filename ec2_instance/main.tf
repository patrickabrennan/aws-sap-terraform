############################################
# Root main.tf — Stable primary, optional HA secondary
############################################
# Assumes data.tf defines:
#   - data.aws_vpc.sap
#   - local.azs_with_subnets  (list of AZs that actually have a subnet)
#   - local.subnet_id_by_az   (map AZ -> subnet id)
#   - null_resource.assert_two_azs (optional guard that >=2 AZs are usable)

############################################
# Auto AZ assignment (no hardcoded values)
############################################

locals {
  # Stable ordering of the input map keys
  names_sorted = sort(keys(var.instances_to_create))

  # Only AZs that truly have subnets (built in data.tf)
  _azs = local.azs_with_subnets

  # Primaries:
  # - If cfg.availability_zone is set AND non-empty after trim, use it.
  # - Else deterministically assign via modulo rotation across _azs.
  primaries = {
    for name, cfg in var.instances_to_create :
    name => merge(cfg, {
      hostname          = try(cfg.hostname, name),
      availability_zone = (
        try(trim(cfg.availability_zone) != "", false)
        ? trim(cfg.availability_zone)
        : local._azs[index(local.names_sorted, name) % length(local._azs)]
      ),
      ha = try(cfg.ha, false)
    })
  }

  # Secondaries:
  # - Only when ha = true
  # - Always the "next" AZ (wrap-around) to ensure cross-AZ
  secondaries = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, {
      hostname          = "${try(cfg.hostname, name)}-b",
      availability_zone = local._azs[(index(local.names_sorted, name) + 1) % length(local._azs)],
      ha                = true
    })
    if try(cfg.ha, false)
  }

  # Full set (primary + optional secondary)
  all_instances = merge(local.primaries, local.secondaries)

  # Final, guarded AZ for every expanded instance key.
  # If v.availability_zone is empty/null, compute a deterministic fallback again.
  az_for_instance = {
    for k, v in local.all_instances :
    k => (
      try(trim(v.availability_zone) != "", false)
      ? trim(v.availability_zone)
      : local._azs[
          (
            index(local.names_sorted, replace(k, "-b", "")) +
            (endswith(k, "-b") ? 1 : 0)
          ) % length(local._azs)
        ]
    )
  }

  # Helpful diagnostics: which instances are blank or missing a mapped subnet
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
  lifecycle {
    precondition {
      condition = length(local.az_blanks) == 0
      error_message = "Some instances computed a blank availability_zone: ${join(", ", local.az_blanks)}. Check azs_with_subnets and instances_to_create."
    }
  }
}

# Guard: ensure every chosen AZ has a mapped subnet id
resource "null_resource" "assert_all_instances_have_subnet" {
  lifecycle {
    precondition {
      condition = length(local.az_without_subnet) == 0
      error_message = "Some instances map to an AZ without a subnet id: ${join(", ", local.az_without_subnet)}. Check subnet_id_by_az in data.tf."
    }
  }
}

############################################
# EC2 instances (primary + optional HA secondary)
############################################
module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = local.all_instances

  # Make sure AZ/subnet guards ran (and optional >=2 AZs guard from data.tf)
  depends_on = [
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

  # Placement — use guarded AZ and per-AZ subnet map (never null/empty)
  availability_zone = local.az_for_instance[each.key]
  subnet_ID         = local.subnet_id_by_az[local.az_for_instance[each.key]]

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
