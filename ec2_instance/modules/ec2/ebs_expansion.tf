locals {
  # ---------- Safe inputs ----------
  custom_ebs_config_input = coalesce(var.custom_ebs_config, [])

  # Default storage types if not set
  hana_data_type   = var.hana_data_storage_type   != "" ? var.hana_data_storage_type   : "gp3"
  hana_logs_type   = var.hana_logs_storage_type   != "" ? var.hana_logs_storage_type   : "gp3"
  hana_backup_type = var.hana_backup_storage_type != "" ? var.hana_backup_storage_type : "st1"
  hana_shared_type = var.hana_shared_storage_type != "" ? var.hana_shared_storage_type : "gp3"

  # ---------- Spec-driven expansions (HANA) ----------
  # Use "default" profile when an instance_type-specific entry doesn't exist
  hana_data = (
    var.application_code == "hana"
    ? try(try(local.hana_data_specs[var.instance_type], local.hana_data_specs["default"])[local.hana_data_type], [])
    : []
  )

  hana_data_expanded = (
    var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_data[0]["disk_nb"], 0))) :
        merge(local.hana_data[0], { disk_index = i })], [])
    : []
  )

  hana_logs = (
    var.application_code == "hana"
    ? try(try(local.hana_logs_specs[var.instance_type], local.hana_logs_specs["default"])[local.hana_logs_type], [])
    : []
  )

  hana_logs_expanded = (
    var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_logs[0]["disk_nb"], 0))) :
        merge(local.hana_logs[0], { disk_index = i })], [])
    : []
  )

  hana_backup = (
    var.application_code == "hana"
    ? try(try(local.hana_backup_specs[var.instance_type], local.hana_backup_specs["default"])[local.hana_backup_type], [])
    : []
  )

  hana_backup_expanded = (
    var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_backup[0]["disk_nb"], 0))) :
        merge(local.hana_backup[0], { disk_index = i })], [])
    : []
  )

  hana_shared = (
    var.application_code == "hana"
    ? try(try(local.hana_shared_specs[var.instance_type], local.hana_shared_specs["default"])[local.hana_shared_type], [])
    : []
  )

  hana_shared_expanded = (
    var.application_code == "hana"
    ? try([for i in range(tonumber(try(local.hana_shared[0]["disk_nb"], 0))) :
        merge(local.hana_shared[0], { disk_index = i })], [])
    : []
  )

  # ---------- Common disks (for HANA/NW) ----------
  # Requires local.common to be defined in ebs_specs_common.tf
  common_disks_expanded = try(flatten([
    for item in local.common[var.application_code] : [
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

  # ---------- Final selection before normalization ----------
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

  # ---------- Normalize every disk so size/type/name are always present ----------
  # Accepts alternative keys (volume_size, size_gb / volume_type, ebs_type)
  normalized_disks = [
    for idx, d in local.all_disks : merge(
      {
        name       = coalesce(lookup(d, "name", null), "disk")
        disk_index = lookup(d, "disk_index", idx)
        size       = (
          can(tonumber(lookup(d, "size", null)))        ? tonumber(lookup(d, "size", null)) :
          can(tonumber(lookup(d, "volume_size", null))) ? tonumber(lookup(d, "volume_size", null)) :
          can(tonumber(lookup(d, "size_gb", null)))     ? tonumber(lookup(d, "size_gb", null)) :
          0
        )
        type       = coalesce(
          lookup(d, "type", null),
          lookup(d, "volume_type", null),
          lookup(d, "ebs_type", null),
          "gp3"
        )
      },
      d
    )
  ]

  # Filter out any malformed entries (size < 1)
  valid_disks = [ for d in local.normalized_disks : d if d.size >= 1 ]

  # Optional: fail fast if anything got filtered out (helps catch spec mistakes)
  invalid_disks = [ for d in local.normalized_disks : d if d.size < 1 ]
  # (If you prefer a hard error, uncomment this precondition and ensure a resource block references it.)
  # resource "null_resource" "assert_valid_disks" {
  #   lifecycle {
  #     precondition {
  #       condition     = length(local.invalid_disks) == 0
  #       error_message = "Some disks had no valid size/type: ${[for d in local.invalid_disks : jsonencode(d)]}"
  #     }
  #   }
  # }

  # Device names to attach in order
  device_names = [
    "/dev/xvdf","/dev/xvdg","/dev/xvdh","/dev/xvdi","/dev/xvdj",
    "/dev/xvdk","/dev/xvdl","/dev/xvdm","/dev/xvdn","/dev/xvdo",
    "/dev/xvdp","/dev/xvdq","/dev/xvdr","/dev/xvds","/dev/xvdt",
    "/dev/xvdu","/dev/xvdv","/dev/xvdw","/dev/xvdx","/dev/xvdy"
  ]

  # Stable for_each keys; always include name and disk_index
  disks_by_key = {
    for idx, d in local.valid_disks :
    format("%03d-%s", idx, d.name) => merge(
      { name = d.name, disk_index = d.disk_index },
      d,
      { seq = idx }
    )
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
