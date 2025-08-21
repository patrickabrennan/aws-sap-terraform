############################################
# Expand instances_to_create for HA
# - If ha = false  -> keep the single node (original name)
# - If ha = true   -> create "<name>-a" in the given AZ, and "<name>-b"
#                     in a different AZ (auto-chosen) unless
#                     partner_availability_zone is provided in the entry.
############################################

#commnet out as I have this in data.tf on 8-21-2025
#data "aws_availability_zones" "this" {
#  state = "available"
#}

locals {
  # convenience list of AZ names
  _all_azs = data.aws_availability_zones.this.names

  # Build the final map used by module for_each
  effective_instances_to_create = merge(
    // Primary nodes (either the original name if not HA, or "<name>-a" if HA)
    {
      for name, cfg in var.instances_to_create :
      (try(cfg.ha, false) ? "${name}-a" : name) => merge(cfg, {
        hostname          = (try(cfg.ha, false) ? "${name}-a" : name)
        # If cfg.availability_zone missing, fallback to first AZ in region
        availability_zone = try(cfg.availability_zone, local._all_azs[0])
      })
    },
    // Secondary nodes for HA ("<name>-b")
    {
      for name, cfg in var.instances_to_create :
      "${name}-b" => merge(cfg, {
        hostname = "${name}-b"

        # partner AZ selection logic:
        # 1) if the entry includes partner_availability_zone, use it
        # 2) otherwise pick the first AZ that differs from the primary AZ
        #    (and if none exist, reuse the same AZ)
        availability_zone = coalesce(
          try(cfg.partner_availability_zone, null),
          try([
            for az in local._all_azs : az
            if az != try(cfg.availability_zone, local._all_azs[0])
          ][0], null),
          try(cfg.availability_zone, local._all_azs[0])
        )
      })
      if try(cfg.ha, false)
    }
  )
}
