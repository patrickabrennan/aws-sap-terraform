locals {
  # Safe input (empty list if none provided)
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])

  # Expand any user-provided custom disks
  custom_ebs_config_expanded = flatten([
    for item in local.custom_ebs_config_input : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ])

  # If you don’t build these elsewhere, keep them empty so the module compiles
  hana_data_expanded    = []
  hana_logs_expanded    = []
  hana_backup_expanded  = []
  hana_shared_expanded  = []
  common_disks_expanded = []

  # Default “standard” layout when no custom config is provided
  standard_disks = concat(
    local.hana_data_expanded,
    local.hana_logs_expanded,
    local.hana_backup_expanded,
    local.hana_shared_expanded,
    local.common_disks_expanded
  )

  # Final list used by resources (wrapped ternary to avoid parse error)
  all_disks = (
    length(local.custom_ebs_config_input) == 0
    ? local.standard_disks
    : local.custom_ebs_config_expanded
  )
}
