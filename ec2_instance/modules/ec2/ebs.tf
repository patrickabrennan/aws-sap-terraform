############################################
# EBS layout + attachments for each instance
############################################

locals {
  # Use the resolved subnet's AZ; fall back to var.availability_zone as a guard
  ebs_instance_az_effective = try(data.aws_subnet.effective.availability_zone, var.availability_zone)

  # Handy defaults for sizes (GB)
  default_size_for = {
    data   = 512
    log    = 256
    backup = 512
    shared = 256
    usrsap = 100
    sapmnt = 100
    swap   = 64
    tmp    = 100
  }

  # Preset layouts
  defaults_hana = [
    { name = "data",   type = coalesce(var.hana_data_storage_type,   "gp3"), size = lookup(local.default_size_for, "data",   512) },
    { name = "log",    type = coalesce(var.hana_logs_storage_type,   "gp3"), size = lookup(local.default_size_for, "log",    256) },
    { name = "backup", type = coalesce(var.hana_backup_storage_type, "st1"), size = lookup(local.default_size_for, "backup", 512) },
    { name = "shared", type = coalesce(var.hana_shared_storage_type, "gp3"), size = lookup(local.default_size_for, "shared", 256) },
    { name = "usrsap", type = "gp3", size = lookup(local.default_size_for, "usrsap", 100) },
    { name = "tmp",    type = "gp3", size = lookup(local.default_size_for, "tmp",    100) },
    { name = "swap",   type = "gp3", size = lookup(local.default_size_for, "swap",    64) },
  ]

  defaults_nw = [
    { name = "usrsap", type = "gp3", size = lookup(local.default_size_for, "usrsap", 100) },
    { name = "sapmnt", type = "gp3", size = lookup(local.default_size_for, "sapmnt", 100) },
    { name = "tmp",    type = "gp3", size = lookup(local.default_size_for, "tmp",    100) },
    { name = "swap",   type = "gp3", size = lookup(local.default_size_for, "swap",    64) },
  ]

  # Treat null as empty list so length() never errors
  custom_ebs_config_safe = coalesce(var.custom_ebs_config, [])

  # Caller-provided custom layout wins; else choose by application_code
  base_disks = (
    length(local.custom_ebs_config_safe) > 0
      ? local.custom_ebs_config_safe
      : (var.application_code == "hana" ? local.defaults_hana : local.defaults_nw)
  )

  # Normalize inputs to a consistent shape (robust to null/strings)
  normalized_disks = [
    for idx, d in tolist(local.base_disks) : {
      name       = coalesce(try(tostring(lookup(d, "name", null)), null), "disk${idx}")
      type       = lower(lookup(d, "type", "gp3"))
      size       = try(tonumber(lookup(d, "size", null)), 50)
      iops       = try(tonumber(lookup(d, "iops", 0)), 0)
      throughput = try(tonumber(lookup(d, "throughput", 0)), 0)
      device     = lookup(d, "device", "")
      disk_index = idx
    }
  ]

  # Deterministic device names if not provided: /dev/xvdf, /dev/xvdg, ...
  device_letters = ["f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

  _device_by_index = {
    for d in local.normalized_disks :
    d.disk_index => (d.device != "" ? d.device : "/dev/xvd${local.device_letters[d.disk_index]}")
  }

  # ---------------------------
  # SPLIT: inline vs external
  # ---------------------------

  # Volumes that should be created inline on the instance and deleted with it
  inline_delete_on_term_names = ["usrsap", "sapmnt", "tmp", "swap"]

  # Inline disks (created by aws_instance.ebs_block_device in ec2.tf)
  inline_disks = [
    for d in local.normalized_disks : merge(d, {
      device = (d.device != "" ? d.device : local._device_by_index[d.disk_index])
    })
    if contains(local.inline_delete_on_term_names, d.name)
  ]

  # External disks (separate EBS resources + attachments)
  external_disks = [
    for d in local.normalized_disks : merge(d, {
      device = (d.device != "" ? d.device : local._device_by_index[d.disk_index])
    })
    if !contains(local.inline_delete_on_term_names, d.name)
  ]

  # Key each EXTERNAL disk so we can for_each reliably
  external_disks_by_key = {
    for d in local.external_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }
}

# --------------------------------
# Create EXTERNAL EBS volumes only
# --------------------------------
resource "aws_ebs_volume" "all_volumes" {
  for_each = local.external_disks_by_key

  availability_zone = local.ebs_instance_az_effective
  size              = each.value.size
  type              = each.value.type

  # Only set iops/throughput when > 0 (and throughput only on gp3)
  iops       = each.value.iops > 0 ? each.value.iops : null
  throughput = (each.value.type == "gp3" && each.value.throughput > 0) ? each.value.throughput : null

  encrypted  = var.kms_key_arn != "" ? true : null
  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}-${each.value.name}"
      Environment = var.environment
      Application = var.application_code
      Hostname    = var.hostname
      Role        = "ebs"
    }
  )

  # Let AWS take its time to purge; Terraform will wait up to this
  timeouts {
    delete = "45m"
  }
}

# Attach EXTERNAL volumes to the launched instance
resource "aws_volume_attachment" "all_attachments" {
  for_each = aws_ebs_volume.all_volumes

  device_name = local.external_disks_by_key[each.key].device
  volume_id   = each.value.id
  instance_id = aws_instance.this.id

  # Ensure safe detach before instance delete/replace
  skip_destroy = false
  force_detach = true

  timeouts {
    delete = "20m"
  }

  # If the instance gets replaced, detach these first
  lifecycle {
    replace_triggered_by = [aws_instance.this.id]
  }

  depends_on = [aws_instance.this]
}
