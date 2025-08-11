########################################
# Attach normalized_disks to the instance
########################################

locals {
  # Unique key per instance+disk so -b never collides with primary
  disks_map = {
    for d in local.normalized_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }

  # Letters for /dev/xvd? fallback
  device_letters = [
    "f","g","h","i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x","y","z",
    "aa","ab","ac","ad","ae","af"
  ]
}

resource "aws_ebs_volume" "all_volumes" {
  for_each          = local.disks_map
  availability_zone = data.aws_subnet.effective.availability_zone

  size       = tonumber(each.value.size)
  type       = lower(each.value.type)
  # Encrypt only when we actually have a KMS key ARN
  encrypted  = local.kms_key_arn_effective != "" ? true : null
  kms_key_id = local.kms_key_arn_effective != "" ? local.kms_key_arn_effective : null

  #encrypted  = true
  #kms_key_id = var.kms_key_arn

  # Only set IOPS when supported and > 0 (gp3, io1, io2)
  iops = (
    contains(["gp3","io1","io2"], each.value.type) && try(tonumber(each.value.iops), 0) > 0
    ? tonumber(each.value.iops)
    : null
  )

  # Only set throughput for gp3 and > 0
  throughput = (
    each.value.type == "gp3" && try(tonumber(each.value.throughput), 0) > 0
    ? tonumber(each.value.throughput)
    : null
  )

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-${each.value.name}-${format("%03d", each.value.disk_index)}"
    environment = var.environment
    role        = "data"
  })
}

resource "aws_volume_attachment" "all_attachments" {
  for_each = local.disks_map

  device_name = coalesce(
    try(each.value.device, null),
    "/dev/xvd${local.device_letters[(try(each.value.disk_index, 0)) % length(local.device_letters)]}"
  )

  volume_id   = aws_ebs_volume.all_volumes[each.key].id
  instance_id = aws_instance.this.id

  force_detach = true

  depends_on = [
    aws_instance.this,
    aws_ebs_volume.all_volumes
  ]

  timeouts {
    create = "15m"
    delete = "15m"
  }
}







/*
########################################
# modules/ec2/ebs.tf
# Consumes local.normalized_disks and attaches safely.
########################################
# Requires:
# - local.normalized_disks (from ebs_expansion.tf)
# - data.aws_subnet.effective (provides availability_zone)
# - data.aws_ssm_parameter.ebs_kms (optional; omit if you don't use it)

locals {
  # Unique key per instance+disk so -a/-b nodes never collide
  disks_map = {
    for d in local.normalized_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }

  # Letters for /dev/xvd? fallback: f,g,h,... (Nitro maps to nvme on guest)
  device_letters = [
    "f","g","h","i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x","y","z",
    "aa","ab","ac","ad","ae","af"
  ]
}

resource "aws_ebs_volume" "all_volumes" {
  for_each          = local.disks_map
  availability_zone = data.aws_subnet.effective.availability_zone

  size       = tonumber(each.value.size)
  type       = lower(each.value.type)
  encrypted  = true
  kms_key_id = try(data.aws_ssm_parameter.ebs_kms.value, null)

  # Set IOPS only when supported and > 0 (gp3, io1, io2)
  iops = (
    contains(["gp3","io1","io2"], each.value.type) && try(tonumber(each.value.iops), 0) > 0
    ? tonumber(each.value.iops)
    : null
  )

  # Set throughput only for gp3 and > 0
  throughput = (
    each.value.type == "gp3" && try(tonumber(each.value.throughput), 0) > 0
    ? tonumber(each.value.throughput)
    : null
  )

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-${each.value.name}-${format("%03d", each.value.disk_index)}"
    environment = var.environment
    role        = "data"
  })
}

resource "aws_volume_attachment" "all_attachments" {
  for_each = local.disks_map

  # Use provided device name if set; otherwise pick a sequential fallback
  device_name = coalesce(
    try(each.value.device, null),
    "/dev/xvd${local.device_letters[(try(each.value.disk_index, 0)) % length(local.device_letters)]}"
  )

  volume_id   = aws_ebs_volume.all_volumes[each.key].id
  instance_id = aws_instance.this.id

  force_detach = true

  depends_on = [
    aws_instance.this,
    aws_ebs_volume.all_volumes
  ]

  timeouts {
    create = "15m"
    delete = "15m"
  }
}
*/
