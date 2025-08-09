locals {

  hana_data          = var.application_code == "hana" ? try(local.hana_data_specs[var.instance_type][var.hana_data_storage_type], []) : []
  hana_data_expanded = var.application_code == "hana" ? try([for item in range(local.hana_data[0]["disk_nb"]) : merge(local.hana_data[0], { "disk_index" : item })], []) : []

  hana_logs          = var.application_code == "hana" ? try(local.hana_logs_specs[var.instance_type][var.hana_logs_storage_type], []) : []
  hana_logs_expanded = var.application_code == "hana" ? try([for item in range(local.hana_logs[0]["disk_nb"]) : merge(local.hana_logs[0], { "disk_index" : item })], []) : []

  hana_backup          = var.application_code == "hana" ? try(local.hana_backup_specs[var.instance_type][var.hana_backup_storage_type], []) : []
  hana_backup_expanded = var.application_code == "hana" ? try([for item in range(local.hana_backup[0]["disk_nb"]) : merge(local.hana_backup[0], { "disk_index" : item })], []) : []

  hana_shared          = var.application_code == "hana" ? try(local.hana_shared_specs[var.instance_type][var.hana_shared_storage_type], []) : []
  hana_shared_expanded = var.application_code == "hana" ? try([for item in range(local.hana_shared[0]["disk_nb"]) : merge(local.hana_shared[0], { "disk_index" : item })], []) : []

  common_disks_expanded = flatten([for item in local.common[var.application_code] : [for i in range(item["disk_nb"]) : merge(item, { "disk_index" : i })]])

  #custom_ebs_config_expanded = flatten([for item in var.custom_ebs_config : [for i in range(item["disk_nb"]) : merge(item, { "disk_index" : i })]])
  custom_ebs_config_expanded = flatten([
    for item in coalesce(var.custom_ebs_config, []) : [
      for i in range(tonumber(item["disk_nb"])) :
      merge(item, { disk_index = i })
    ]
  ])
}




  standard_disks = concat(local.hana_data_expanded, local.hana_logs_expanded, local.hana_backup_expanded, local.hana_shared_expanded, local.common_disks_expanded)

  all_disks = var.custom_ebs_config == [] ? local.standard_disks : local.custom_ebs_config_expanded
}
