########################################
# EBS volumes + attachments (module)
########################################

# Use the AZ from the selected subnet; fall back to var.availability_zone
locals {
  ebs_instance_az_effective = try(data.aws_subnet.effective[0].availability_zone, var.availability_zone)

  # Reasonable default sizes (GB)
  default_size_for = {
    data   = 512
    log    = 256
    backup = 1024
    shared = 100
    usrsap = 100
    sapmnt = 100
    tmp    = 50
    swap   = 32
    disk   = 50
  }

  #############################
  # Default disk layouts
  #############################
  defaults_hana = [
    # You can tweak sizes/types here or pass custom_ebs_config to override
    { name = "data",   type = coalesce(var.hana_data_storage_type,   "gp3"), size = lookup(local.default_size_for, "data",   512) },
    { name = "log",    type = coalesce(var.hana_logs_storage_type,   "gp3"), size = lookup(local.default_size_for, "log",    256) },
    { name = "backup", type = coalesce(var.hana_backup_storage_type, "st1"), size = lookup(local.default_size_for, "backup", 1024) },
    { name = "shared", type = coalesce(var.hana_shared_storage_type, "gp3"), size = lookup(local.default_size_for, "shared", 100) }
  ]

  defaults_nw = [
    { name = "usrsap", type = "gp3", size = lookup(local.default_size_for, "usrsap", 100) },
    { name = "sapmnt", type = "gp3", size = lookup(local.default_size_for, "sapmnt", 100) },
    { name = "tmp",    type = "gp3", size = lookup(local.default_size_for, "tmp",     50) },
    { name = "swap",   type = "gp3", size = lookup(local.default_size_for, "swap",    32) }
  ]

  # Source list: custom override > HANA > NW
  source_disks = length(var.custom_ebs_config) > 0
    ? var.custom_ebs_config
    : (var.application_code == "hana" ? local.defaults_hana : local.defaults_nw)

  # Expand "disk_nb" into multiple entries; default disk_index is sequential
  expanded_disks = flatten([
    for item in local.source_disks : (
      try(tonumber(lookup(item, "disk_nb", 1)), 1) > 1
        ? [for i in range(try(tonumber(lookup(item, "disk_nb", 1)), 1)) : merge(item, { disk_index = i })]
        : [merge(item, { disk_index = try(tonumber(lookup(item, "disk_index", 0)), 0) })]
    )
  ])

  # Normalize into a list
  normalized_list = [
    for idx, d in local.expanded_disks : {
      name       = trim(lower(coalesce(lookup(d, "name", null), lookup(d, "identifier", null), "disk")))
      disk_index = try(tonumber(lookup(d, "disk_index", idx)), idx)
      size = (
        try(tonumber(lookup(d, "size",        0)), 0) > 0 ? try(tonumber(lookup(d, "size",        0)), 0) :
        try(tonumber(lookup(d, "disk_size",   0)), 0) > 0 ? try(tonumber(lookup(d, "disk_size",   0)), 0) :
        try(tonumber(lookup(d, "volume_size", 0)), 0) > 0 ? try(tonumber(lookup(d, "volume_size", 0)), 0) :
        try(tonumber(lookup(d, "size_gb",     0)), 0) > 0 ? try(tonumber(lookup(d, "size_gb",     0)), 0) :
        lookup(local.default_size_for, lower(lookup(d, "identifier", lookup(d, "name", "disk"))), 50)
      )
      type       = coalesce(
                    lookup(d, "type",        null),
                    lookup(d, "disk_type",   null),
                    lookup(d, "volume_type", null),
                    lookup(d, "ebs_type",    null),
                    "gp3"
                  )
      iops       = try(tonumber(lookup(d, "iops", 0)), 0)
      throughput = try(tonumber(lookup(d, "throughput", 0)), 0)
    }
  ]

  # Convert to a map keyed by "<hostname>|<000>|<name>" — guarantees uniqueness
  normalized_disks = {
    for d in local.normalized_list :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }

  # Stable device names: /dev/xvd[f..z]
  device_letters = ["f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
  device_map     = {
    for k, d in local.normalized_disks :
    k => "/dev/xvd${local.device_letters[min(d.disk_index, length(local.device_letters)-1)]}"
  }
}

# -----------------------------
# Create EBS volumes
# -----------------------------
resource "aws_ebs_volume" "all_volumes" {
  for_each = local.normalized_disks

  # CRITICAL: Create volumes in the instance/subnet AZ
  availability_zone = local.ebs_instance_az_effective

  size = each.value.size
  type = each.value.type

  # Set IOPS/Throughput only when valid for the chosen type
  iops = (
    each.value.iops > 0 && contains(["io1", "io2", "gp3"], each.value.type)
      ? each.value.iops
      : null
  )

  throughput = (
    each.value.type == "gp3" && each.value.throughput > 0
      ? each.value.throughput
      : null
  )

  # Optional KMS encryption
  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
  encrypted  = var.kms_key_arn != "" ? true            : null

  tags = merge(
    var.ec2_tags,
    {
      Name        = "${var.hostname}|${format("%03d", each.value.disk_index)}|${each.value.name}"
      Environment = var.environment
      Hostname    = var.hostname
      Application = var.application_code
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  # Make sure the subnet/ AZ selection happened first
  depends_on = [null_resource.assert_single_subnet]
}

# -----------------------------
# Attach EBS volumes
# -----------------------------
resource "aws_volume_attachment" "all_attachments" {
  for_each = aws_ebs_volume.all_volumes

  instance_id = aws_instance.this.id
  volume_id   = each.value.id
  device_name = lookup(local.device_map, each.key, "/dev/xvdf")
}
