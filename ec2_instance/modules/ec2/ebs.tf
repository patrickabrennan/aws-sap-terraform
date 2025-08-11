########################################
# modules/ec2/ebs.tf  (REPLACE)
########################################
# Requires:
# - local.all_disks  (list of disk objects from ebs_expansion.tf)
# - data.aws_subnet.effective (for AZ)
# - data.aws_ssm_parameter.ebs_kms (optional KMS)

locals {
  # Make sure each disk has a name and index; fall back gracefully if fields are missing
  all_disks_list = tolist(local.all_disks)

  normalized_disks = [
    for idx, d in local.all_disks_list : merge(d, {
      name       = coalesce(
                     try(tostring(d.name), null),
                     try(tostring(d.label), null),
                     try(tostring(d.volume_name), null),
                     try(tostring(d.mount), null),
                     "disk"
                   )
      disk_index = try(d.disk_index, idx)
    })
  ]

  # Unique key per *instance* and *disk* so volumes never collide across -a/-b
  all_disks_map = {
    for d in local.normalized_disks :
    "${var.hostname}|${format("%03d", d.disk_index)}|${d.name}" => d
  }
}

resource "aws_ebs_volume" "all_volumes" {
  for_each          = local.all_disks_map
  availability_zone = data.aws_subnet.effective.availability_zone

  size = tonumber(lookup(each.value, "size",
         lookup(each.value, "volume_size", 0)))
  type       = lookup(each.value, "type", "gp3")
  encrypted  = true
  kms_key_id = try(data.aws_ssm_parameter.ebs_kms.value, null)

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-${each.value.name}-${format("%03d", each.value.disk_index)}"
    environment = var.environment
    role        = "data"
  })
}

resource "aws_volume_attachment" "all_attachments" {
  for_each    = local.all_disks_map
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

  # Optional guard if you're unsure device is always set:
  lifecycle {
    precondition {
      condition     = can(each.value.device) && each.value.device != ""
      error_message = "Device name not set for disk ${each.key}"
    }
  }
}
