########################################
# ha_expand.tf
########################################

# Expands var.instances_to_create into one or two nodes per logical host.
locals {
  expanded_instances = merge(
    # Primary node (always)
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
