############################################
# Root main.tf — Stable primary, optional HA secondary
############################################
# Assumes you already have in data.tf:
# - data.aws_vpc.sap
# - local.azs_with_subnets
# - local.subnet_id_by_az
# - (optionally) null_resource.assert_two_azs

############################################
# Auto AZ assignment (no hardcoded values)
############################################
locals {
  names_sorted = sort(keys(var.instances_to_create))
  _azs         = local.azs_with_subnets

  # Primaries: explicit AZ if provided and non-empty; else deterministic rotation
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

  # Secondaries: next AZ (wrap) when ha = true
  secondaries = {
    for name, cfg in var.instances_to_create :
    "${name}-b" => merge(cfg, {
      hostname          = "${try(cfg.hostname, name)}-b",
      availability_zone = local._azs[(index(local.names_sorted, name) + 1) % length(local._azs)],
      ha                = true
    })
    if try(cfg.ha, false)
  }

  # Full set
  all_instances = merge(local.primaries, local.secondaries)

  # Final guard: guaranteed AZ per expanded instance (never null/empty)
  az_for_instance = {
    for k, v in local.all_instances :
    k => (
      try(trim(v.availability_zone) != "", false)
      ? trim(v.availability_zone)
      : local._azs[index(local.names_sorted, replace(k, "-b", "")) % length(local._azs)]
    )
  }
}

# Guard: ensure every expanded instance has a non-empty AZ
resource "null_resource" "assert_all_instances_have_az" {
  lifecycle {
    precondition {
      condition = alltrue([
        for k, az in local.az_for_instance : try(trim(az) != "", false)
      ])
      error_message = "Some instances computed a blank availability_zone. Check azs_with_subnets and instances_to_create."
    }
  }
}

############################################
# EC2 instances (primary + optional HA secondary)
############################################
module "ec2_instances" {
  source   = "./modules/ec2"
  for_each = local.all_instances

  # Ensure upstream AZ/Subnet guards ran (assert_two_azs is defined in data.tf)
  depends_on = [
    null_resource.assert_all_instances_have_az,
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

  # Placement — use guarded AZ and per-AZ subnet map
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
