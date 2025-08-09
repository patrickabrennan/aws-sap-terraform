locals {
  # ---------- Inputs ----------
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])  # <— never null

  # Normalize application code ("HANA" vs "hana")
  app = lower(var.application_code)

  # Default storage types if not set
  hana_data_type   = var.hana_data_storage_type   != "" ? var.hana_data_storage_type   : "gp3"
  hana_logs_type   = var.hana_logs_storage_type   != "" ? var.hana_logs_storage_type   : "gp3"
  hana_backup_type = var.hana_backup_storage_type != "" ? var.hana_backup_storage_type : "st1"
  hana_shared_type = var.hana_shared_storage_type != "" ? var.hana_shared_storage_type : "gp3"

  # ---------- Spec-driven expansions (HANA) ----------
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

  # ---------- Custom layout override (optional) ----------
  custom_ebs_config_expanded = flatten([
    for item in local.custom_ebs_config_input : [
      for i in range(tonumber(lookup(item, "disk_nb", 0))) :
      merge(item, { disk_index = i })
    ]
  ])

  # ---------- Selection before normalization ----------
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

  # ---------- Normalize every disk (NO null size/type) ----------
  default_size_for = {
    "usr-sap" = 100,
    "trans"   = 100,
    "sapmnt"  = 100,
    "diag"    = 50,
    "tmp"     = 50,
  }

  normalized_disks = [
    for idx, d in local.all_disks : {
      name       = (lookup(d, "name", null) != null ? lookup(d, "name", null) : "disk")
      disk_index = lookup(d, "disk_index", idx)

      # Pull size from any known key; if <= 0, fall back by name (or 50 GiB)
      size = (
        (try(tonumber(lookup(d, "size", 0)), 0) > 0)         ? try(tonumber(lookup(d, "size", 0)), 0) :
        (try(tonumber(lookup(d, "volume_size", 0)), 0) > 0)  ? try(tonumber(lookup(d, "volume_size", 0)), 0) :
        (try(tonumber(lookup(d, "size_gb", 0)), 0) > 0)      ? try(tonumber(lookup(d, "size_gb", 0)), 0) :
        lookup(local.default_size_for, lower(lookup(d, "name", "")), 50)
      )

      type = lookup(d, "type",
              lookup(d, "volume_type",
              lookup(d, "ebs_type", "gp3")))
    }
  ]

  # Device names to attach in order
  device_names = [
    "/dev/xvdf","/dev/xvdg","/dev/xvdh","/dev/xvdi","/dev/xvdj",
    "/dev/xvdk","/dev/xvdl","/dev/xvdm","/dev/xvdn","/dev/xvdo",
    "/dev/xvdp","/dev/xvdq","/dev/xvdr","/dev/xvds","/dev/xvdt",
    "/dev/xvdu","/dev/xvdv","/dev/xvdw","/dev/xvdx","/dev/xvdy"
  ]

  # Stable for_each keys
  disks_by_key = {
    for idx, d in local.normalized_disks :
    format("%03d-%s", idx, d.name) => merge(d, { seq = idx })
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
