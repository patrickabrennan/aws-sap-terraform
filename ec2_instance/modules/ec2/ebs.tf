########################################
# modules/ec2/ebs.tf  (REPLACE)
########################################
# Expects:
# - local.normalized_disks from ebs_expansion.tf, each with:
#   name, disk_index, size, type, device (optional iops, throughput)
# - data.aws_subnet.effective (for AZ)
# - data.aws_ssm_parameter.ebs_kms (optional KMS)

locals {
  # Unique key per instance+disk so volumes never collide across -a/-b nodes
  disks_map = {
    for d in local.normalized_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }
}

resource "aws_ebs_volume" "all_volumes" {
  for_each          = local.disks_map
  availability_zone = data.aws_subnet.effective.availability_zone

  size       = tonumber(each.value.size)
  type       = each.value.type
  encrypted  = true
  kms_key_id = try(data.aws_ssm_parameter.ebs_kms.value, null)

  # Only set IOPS when supported and >0 (gp3/io1/io2). Otherwise omit.
  iops = (
    contains(["gp3", "io1", "io2"], lower(each.value.type)) && try(tonumber(each.value.iops), 0) > 0
    ? tonumber(each.value.iops)
    : null
  )

  # Only set throughput for gp3 and when >0. Otherwise omit.
  throughput = (
    lower(each.value.type) == "gp3" && try(tonumber(each.value.throughput), 0) > 0
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
  for_each    = local.disks_map
  device_name = each.value.device
  volume_id   = aws_ebs_volume.all_volumes[each.key].id
  instance_id = aws_instance.this.id

  # Be resilient during re-plans / HA toggles
  force_detach = true

  depends_on = [
    aws_instance.this,
    aws_ebs_volume.all_volumes
  ]

  timeouts {
    create = "15m"
    delete = "15m"
  }

  lifecycle {
    precondition {
      condition     = can(each.value.device) && each.value.device != ""
      error_message = "Device name not set for disk ${each.key}"
    }
  }
}
