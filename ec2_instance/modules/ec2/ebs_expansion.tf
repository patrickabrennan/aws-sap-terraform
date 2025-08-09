locals {
  # ---------- Safe inputs ----------
  # Ensure callers can omit custom_ebs_config without crashing
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])

  # If HANA types aren't provided, use sensible defaults
  hana_data_type   = var.hana_data_storage_type   != "" ? var.hana_data_storage_type   : "gp3"
  hana_logs_type   = var.hana_logs_storage_type   != "" ? var.hana_logs_storage_type   : "gp3"
  hana_backup_type = var.hana_backup_storage_type != "" ? var.hana_backup_storage_type : "st1"
  hana_shared_type = var.hana_shared_storage_type != "" ? var.hana_shared_storage_type : "gp3"

  # ---------- Original, spec-driven expansions (HANA) ----------
  # Expecting spec maps defined elsewhere like:
  # local.hana_data_specs[var.instance_type][<type>] -> [ { size, type, disk_nb, ... } ]
  hana_data = var.application_code == "hana"
    ? try(local.hana_data_specs[var.instance_type][local.hana_data_type], [])
    : []

  hana_data_expanded = var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_data[0]["disk_nb"], 0))) :
        merge(local.hana_data[0], { disk_index = i })], [])
    : []

  hana_logs = var.application_code == "hana"
    ? try(local.hana_logs_specs[var.instance_type][local.hana_logs_type], [])
    : []

  hana_logs_expanded = var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_logs[0]["disk_nb"], 0))) :
        merge(local.hana_logs[0], { disk_index = i })], [])
    : []

  hana_backup = var.application_code == "hana"
    ? try(local.hana_backup_specs[var.instance_type][local.hana_backup_type], [])
    : []

  hana_backup_expanded = var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_backup[0]["disk_nb"], 0))) :
        merge(local.hana_backup[0], { disk_index = i })], [])
    : []

  hana_shared = var.application_code == "hana"
    ? try(local.hana_shared_specs[var.instance_type][local.hana_shared_type], [])
    : []

  hana_shared_expanded = var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_shared[0]["disk_nb"], 0))) :
        merge(local.hana_shared[0], { disk_index = i })], [])
    : []

  # ---------- Original, common disks (applies to HANA/NW via local.common) ----------
  # Expecting: local.common["hana"] / local.common["nw"] -> list of { size, type, disk_nb, ... }
  common_disks_expanded = try(flatten([
    for item in local.common[var.application_code] : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ]), [])

  # ---------- User-provided custom layout (optional override) ----------
  custom_ebs_config_expanded = flatten([
    for item in local.custom_ebs_config_input : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ])

  # ---------- Final selections ----------
  # This matches your original logic:
  # - If custom list is provided (non-empty), use it.
  # - Otherwise, use the standard, spec-driven layout (HANA+common or NW+common).
  standard_disks = concat(
    local.hana_data_expanded,
    local.hana_logs_expanded,
    local.hana_backup_expanded,
    local.hana_shared_expanded,
    local.common_disks_expanded
  )

  all_disks = (
    length(local.custom_ebs_config_input) == 0
    ? local.standard_disks
    : local.custom_ebs_config_expanded
  )
}




#locals {
#  # Safe input (empty list if none provided)
#  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])

#  # Expand any user-provided custom disks
#  custom_ebs_config_expanded = flatten([
#    for item in local.custom_ebs_config_input : [
#      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
#      merge(item, { disk_index = i })
#    ]
#  ])

#  # If you don’t build these elsewhere, keep them empty so the module compiles
#  hana_data_expanded    = []
#  hana_logs_expanded    = []
#  hana_backup_expanded  = []
#  hana_shared_expanded  = []
#  common_disks_expanded = []

#  # Default “standard” layout when no custom config is provided
#  standard_disks = concat(
#    local.hana_data_expanded,
#    local.hana_logs_expanded,
#    local.hana_backup_expanded,
#    local.hana_shared_expanded,
#    local.common_disks_expanded
#  )

#  # Final list used by resources (wrapped ternary to avoid parse error)
#  all_disks = (
#    length(local.custom_ebs_config_input) == 0
#    ? local.standard_disks
#    : local.custom_ebs_config_expanded
#  )
#}
