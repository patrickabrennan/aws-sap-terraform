########################################
# modules/ec2/ebs_expansion.tf
# Builds a complete, flat disk list and normalizes it.
# Produces: local.normalized_disks
########################################

locals {
  app = lower(var.application_code)

  # ---------- Defaults (safe, minimal) ----------
  # Common disks by app (adjust sizes/types as you prefer)
  defaults_common_map = {
    hana = [
      { name = "usrsap", type = "gp3", size = 100, disk_nb = 1 },
      { name = "trans",  type = "gp3", size = 100, disk_nb = 1 },
      { name = "sapmnt", type = "gp3", size = 100, disk_nb = 1 },
      { name = "tmp",    type = "gp3", size =  50, disk_nb = 1 },
      { name = "diag",   type = "gp3", size =  50, disk_nb = 1 },
    ]
    nw = [
      { name = "usrsap", type = "gp3", size = 100, disk_nb = 1 },
      { name = "sapmnt", type = "gp3", size = 100, disk_nb = 1 },
      { name = "tmp",    type = "gp3", size =  50, disk_nb = 1 },
      { name = "swap",   type = "gp3", size =  16, disk_nb = 1 },
    ]
  }

  # HANA layouts derived from *requested* storage types
  hana_data_type   = lower(coalesce(var.hana_data_storage_type,   "gp3"))
  hana_logs_type   = lower(coalesce(var.hana_logs_storage_type,   "gp3"))
  hana_backup_type = lower(coalesce(var.hana_backup_storage_type, "st1"))
  hana_shared_type = lower(coalesce(var.hana_shared_storage_type, "gp3"))

  # Base specs; sizes are typical and can be tuned
  defaults_hana_data   = { (local.hana_data_type)   = [{ name = "data",   type = local.hana_data_type,   size = 512, disk_nb = 4 }] }
  defaults_hana_logs   = { (local.hana_logs_type)   = [{ name = "log",    type = local.hana_logs_type,   size = 256, disk_nb = 2 }] }
  defaults_hana_backup = { (local.hana_backup_type) = [{ name = "backup", type = local.hana_backup_type, size = 1024, disk_nb = 1 }] }
  defaults_hana_shared = { (local.hana_shared_type) = [{ name = "shared", type = local.hana_shared_type, size = 100, disk_nb = 1 }] }

  # ---------- Expand helpers ----------
  expand_list = flatten([
    for item in varlist : [
      for i in range(try(tonumber(lookup(item, "disk_nb", 1)), 1)) :
      merge(item, { disk_index = i })
    ]
  ]) if length(varlist) > 0 else []

  # Expanded groups
  common_expanded = local.expand_list(varlist = lookup(local.defaults_common_map, local.app, []))

  hana_data_expanded   = local.app == "hana" ? local.expand_list(varlist = lookup(local.defaults_hana_data,   local.hana_data_type,   [])) : []
  hana_logs_expanded   = local.app == "hana" ? local.expand_list(varlist = lookup(local.defaults_hana_logs,   local.hana_logs_type,   [])) : []
  hana_backup_expanded = local.app == "hana" ? local.expand_list(varlist = lookup(local.defaults_hana_backup, local.hana_backup_type, [])) : []
  hana_shared_expanded = local.app == "hana" ? local.expand_list(varlist = lookup(local.defaults_hana_shared, local.hana_shared_type, [])) : []

  # Custom EBS config (if user provided)
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])
  custom_ebs_config_expanded = flatten([
    for item in local.custom_ebs_config_input : [
      for i in range(try(tonumber(lookup(item, "disk_nb", 1)), 1)) :
      merge(item, { disk_index = i })
    ]
  ])

  # Standard layout for this app
  standard_disks = concat(
    local.common_expanded,
    local.hana_data_expanded,
    local.hana_logs_expanded,
    local.hana_backup_expanded,
    local.hana_shared_expanded
  )

  # Final list to use (custom wins if provided)
  final_all_disks = length(local.custom_ebs_config_input) > 0 ? local.custom_ebs_config_expanded : local.standard_disks

  # ---------- Normalize ----------
  # Force unique, sequential disk_index across the entire list (0..N)
  normalized_disks = [
    for idx, d in tolist(local.final_all_disks) : {
      name       = coalesce(
                     try(tostring(lookup(d, "name", null)), null),
                     try(tostring(lookup(d, "identifier", null)), null),
                     try(tostring(lookup(d, "label", null)), null),
                     "disk${idx}"
                   )
      disk_index = idx

      size = (
        try(tonumber(lookup(d, "size", null)), null) != null && tonumber(lookup(d, "size", 0)) > 0 ? tonumber(lookup(d, "size", 0)) :
        try(tonumber(lookup(d, "disk_size", null)), null) != null && tonumber(lookup(d, "disk_size", 0)) > 0 ? tonumber(lookup(d, "disk_size", 0)) :
        try(tonumber(lookup(d, "volume_size", null)), null) != null && tonumber(lookup(d, "volume_size", 0)) > 0 ? tonumber(lookup(d, "volume_size", 0)) :
        50
      )

      type       = lower(lookup(d, "type", "gp3"))
      device     = lookup(d, "device", "")           # optional; fallback assigned in ebs.tf
      iops       = try(tonumber(lookup(d, "iops", 0)), 0)
      throughput = try(tonumber(lookup(d, "throughput", 0)), 0)
    }
  ]
}
