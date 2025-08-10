locals {
  # ---------- Inputs (never null) ----------
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])
  app = lower(var.application_code)

  # Defaults for storage types if unset
  hana_data_type   = var.hana_data_storage_type   != "" ? var.hana_data_storage_type   : "gp3"
  hana_logs_type   = var.hana_logs_storage_type   != "" ? var.hana_logs_storage_type   : "gp3"
  hana_backup_type = var.hana_backup_storage_type != "" ? var.hana_backup_storage_type : "st1"
  hana_shared_type = var.hana_shared_storage_type != "" ? var.hana_shared_storage_type : "gp3"

  # ---------- HANA spec selection (fallback to "default" profile) ----------
  # Requires locals in ebs_specs_hana.tf: hana_*_specs
  hana_data = (
    local.app == "hana"
    ? try(try(local.hana_data_specs[var.instance_type], local.hana_data_specs["default"])[local.hana_data_type], [])
    : []
  )
  hana_data_expanded = (
    local.app == "hana"
    ? try([for i in range(tonumber(try(local.hana_data[0]["disk_nb"], 0))) :
        merge(local.hana_data[0], { disk_index = i })], [])
    : []
  )

  hana_logs = (
    local.app == "hana"
    ? try(try(local.hana_logs_specs[var.instance_type], local.hana_logs_specs["default"])[local.hana_logs_type], [])
    : []
  )
  hana_logs_expanded = (
    local.app == "hana"
    ? try([for i in range(tonumber(try(local.hana_logs[0]["disk_nb"], 0))) :
        merge(local.hana_logs[0], { disk_index = i })], [])
    : []
  )

  hana_backup = (
    local.app == "hana"
    ? try(try(local.hana_backup_specs[var.instance_type], local.hana_backup_specs["default"])[local.hana_backup_type], [])
    : []
  )
  hana_backup_expanded = (
    local.app == "hana"
    ? try([for i in range(tonumber(try(local.hana_backup[0]["disk_nb"], 0))) :
        merge(local.hana_backup[0], { disk_index = i })], [])
    : []
  )

  hana_shared = (
    local.app == "hana"
    ? try(try(local.hana_shared_specs[var.instance_type], local.hana_shared_specs["default"])[local.hana_shared_type], [])
    : []
  )
  hana_shared_expanded = (
    local.app == "hana"
    ? try([for i in range(tonumber(try(local.hana_shared[0]["disk_nb"], 0))) :
        merge(local.hana_shared[0], { disk_index = i })], [])
    : []
  )

  # ---------- Common disks (requires local.common in ebs_specs_common.tf) ----------
  common_disks_expanded = try(flatten([
    for item in local.common[local.app] : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ]), [])

  # ---------- Custom override (optional) ----------
  custom_ebs_config_expanded = flatten([
    for item in local.custom_ebs_config_input : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ])

  # ---------- Selection ----------
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

  # ---------- Normalize fields (repo schema -> volume schema) ----------
  # Accept: identifier/name, disk_size/size/size_gb/volume_size, disk_type/type/volume_type/ebs_type
  default_size_for = {
    "usr-sap" = 100,
    "trans"   = 100,
    "sapmnt"  = 100,
    "diag"    = 50,
    "tmp"     = 50,
  }

  normalized_disks = [
    for idx, d in local.all_disks : {
      name       = coalesce(lookup(d, "name", null), lookup(d, "identifier", null), "disk")
      disk_index = lookup(d, "disk_index", idx)
      size = (
        (try(tonumber(lookup(d, "size", 0)), 0) > 0)        ? try(tonumber(lookup(d, "size", 0)), 0) :
        (try(tonumber(lookup(d, "disk_size", 0)), 0) > 0)   ? try(tonumber(lookup(d, "disk_size", 0)), 0) :
        (try(tonumber(lookup(d, "volume_size", 0)), 0) > 0) ? try(tonumber(lookup(d, "volume_size", 0)), 0) :
        (try(tonumber(lookup(d, "size_gb", 0)), 0) > 0)     ? try(tonumber(lookup(d, "size_gb", 0)), 0) :
        lookup(local.default_size_for, lower(lookup(d, "identifier", lookup(d,"name",""))), 50)
      )
      type       = coalesce(
                     lookup(d, "type", null),
                     lookup(d, "disk_type", null),
                     lookup(d, "volume_type", null),
                     lookup(d, "ebs_type", null),
                     "gp3"
                   )
      iops       = try(tonumber(lookup(d, "iops", 0)), 0)
      throughput = try(tonumber(lookup(d, "throughput", 0)), 0)
    }
  ]

  # ---------- Device naming ----------
  device_names = [
    "/dev/xvdf","/dev/xvdg","/dev/xvdh","/dev/xvdi","/dev/xvdj",
    "/dev/xvdk","/dev/xvdl","/dev/xvdm","/dev/xvdn","/dev/xvdo",
    "/dev/xvdp","/dev/xvdq","/dev/xvdr","/dev/xvds","/dev/xvdt",
    "/dev/xvdu","/dev/xvdv","/dev/xvdw","/dev/xvdx","/dev/xvdy"
  ]

  # Give each final disk a unique, global attach_index for device mapping
  ordered_disks = local.normalized_disks

  # Stable for_each keys + attach_index (do NOT use disk_index for device names)
  disks_by_key = {
    for idx, d in local.ordered_disks :
    format("%03d-%s", idx, d.name) => merge(d, { attach_index = idx })
  }
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
