########################################
# modules/ec2/ec2.tf
# EC2 instance using the ENI + inline EBS, with per-volume tags
########################################

locals {
  # Defaults for sizes (GB)
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

  # Preset layouts (used when custom_ebs_config is empty)
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

  # Normalize inputs to a consistent shape
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

  # Disks keyed with computed device name (for dynamic inline blocks)
  inline_disks_by_key = {
    for d in local.normalized_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => merge(d, {
      device = (d.device != "" ? d.device : local._device_by_index[d.disk_index])
    })
  }

  # Deterministic order for defining blocks
  inline_disk_map_sorted = {
    for k in sort(keys(local.inline_disks_by_key)) :
    k => local.inline_disks_by_key[k]
  }

  # Map device_name -> friendly disk name (for per-volume Name tags)
  device_to_disk_name = {
    for k, v in local.inline_disks_by_key :
    v.device => v.name
  }
}

resource "aws_instance" "this" {
  ami           = var.ami_ID
  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = var.monitoring

  # Use the pre-created primary ENI
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this.id
  }

  # IAM instance profile (resolved in data.tf; kept stable to avoid primary churn)
  iam_instance_profile = local.iam_instance_profile_name_effective

  # Root volume
  root_block_device {
    volume_size           = tonumber(var.root_ebs_size)
    volume_type           = "gp3"
    encrypted             = local.kms_key_arn_effective != "" ? true : null
    kms_key_id            = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null
    delete_on_termination = true
  }

  # Inline data volumes (delete quickly with the instance)
  dynamic "ebs_block_device" {
    for_each = local.inline_disk_map_sorted
    content {
      device_name           = ebs_block_device.value.device
      volume_type           = ebs_block_device.value.type
      volume_size           = ebs_block_device.value.size
      iops                  = ebs_block_device.value.iops > 0 ? ebs_block_device.value.iops : null
      throughput            = (ebs_block_device.value.type == "gp3" && ebs_block_device.value.throughput > 0) ? ebs_block_device.value.throughput : null
      encrypted             = local.kms_key_arn_effective != "" ? true : null
      kms_key_id            = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null
      delete_on_termination = true
    }
  }

#New tag block 8/28/2025
# Common tags for all volumes (root + data).
# (Name is set here for all volumes to avoid separate tag resources.)
volume_tags = merge(
  var.ec2_tags,
  {
    Environment = var.environment
    Application = var.application_code
    Hostname    = var.hostname
    Name        = var.hostname
  }
)



OLD TG BLOCK 8/28/2029 cooment out
#Common tags for all volumes (root + data). Name is set per-volume below.
#  volume_tags = merge(
#    var.ec2_tags,
#    {
#      Environment = var.environment
#      Application = var.application_code
#      Hostname    = var.hostname
#    }
#  )

  tags = merge(var.ec2_tags, {
    Name         = var.hostname
    environment  = var.environment
    domain       = var.domain
    app_code     = var.application_code
    app_sid      = var.application_SID
    ha           = tostring(var.ha)
  })

  # Keep PRIMARY stable when removing SECONDARY
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      iam_instance_profile,
      network_interface,
      ebs_block_device,
      tags["ha"],
    ]
  }

  depends_on = [
    aws_network_interface.this,
    null_resource.assert_single_subnet
  ]
}

#comment out on 8/28/205
/*
# ---- Per-volume Name tags ----

# Tag ROOT as "<hostname>-root"
resource "aws_ec2_tag" "root_name" {
  resource_id = aws_instance.this.root_block_device[0].volume_id
  key         = "Name"
  value       = "${var.hostname}-root"
  depends_on  = [aws_instance.this]
}

# Tag DATA volumes as "<hostname>-<diskname>" by iterating the set as a map keyed by device_name
resource "aws_ec2_tag" "data_names" {
  for_each = {
    for bd in aws_instance.this.ebs_block_device :
    bd.device_name => bd
  }

  resource_id = each.value.volume_id
  key         = "Name"
  value       = "${var.hostname}-${lookup(local.device_to_disk_name, each.key, each.key)}"

  depends_on  = [aws_instance.this]
}
*/










#OLD SETTING
/*
########################################
# modules/ec2/ec2.tf
# EC2 instance using the ENI from eni.tf
########################################

resource "aws_instance" "this" {
  ami           = var.ami_ID
  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = var.monitoring

  # attach the ENI created in eni.tf
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this.id
  }

  # IAM instance profile (string name from SSM in data.tf)
  iam_instance_profile = (
    var.ha
    ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
    : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
  )

  # Ensure the root volume is deleted when the instance is terminated
  root_block_device {
    volume_size           = tonumber(var.root_ebs_size)
    volume_type           = "gp3"
    delete_on_termination = true

    # Encrypt root if a key is provided via your existing local
    encrypted  = local.kms_key_arn_effective != "" ? true : null
    kms_key_id = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null
  }

  tags = merge(var.ec2_tags, {
    Name         = var.hostname
    environment  = var.environment
    domain       = var.domain
    app_code     = var.application_code
    app_sid      = var.application_SID
    ha           = tostring(var.ha)
  })

  lifecycle {
    # Keep this if you want to avoid downtime when Terraform must replace
    create_before_destroy = true
  }
}
*/
