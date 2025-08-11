########################################
# EBS Volumes + Attachments (HA-safe)
########################################

# Expect a list of disks in local.all_disks (built by your ebs_expansion.tf)
# Each disk object should include keys: name, size (or volume_size), type, device, disk_index

# Build a per-instance unique key so volumes never collide across nodes
locals {
  all_disks_map = {
    for d in local.all_disks :
    # key example: sapd01cs-a|002|hana-logs
    "${var.hostname}|${format("%03d", try(d.disk_index, 0))}|${d.name}" => d
  }
}

# Create volumes in the instance's subnet AZ
resource "aws_ebs_volume" "all_volumes" {
  for_each          = local.all_disks_map
  availability_zone = data.aws_subnet.effective.availability_zone

  size = tonumber(lookup(each.value, "size",
         lookup(each.value, "volume_size", 0)))
  type       = lookup(each.value, "type", "gp3")
  encrypted  = true
  kms_key_id = try(data.aws_ssm_parameter.ebs_kms.value, null)

  tags = merge(var.ec2_tags, {
    Name        = "${var.hostname}-${each.value.name}-${format("%03d", try(each.value.disk_index, 0))}"
    environment = var.environment
    role        = "data"
  })
}

# Attach with robust ordering and timeouts to avoid IncorrectState
resource "aws_volume_attachment" "all_attachments" {
  for_each    = local.all_disks_map
  device_name = each.value.device
  volume_id   = aws_ebs_volume.all_volumes[each.key].id
  instance_id = aws_instance.this.id

  # be resilient on re-plans / toggles
  force_detach = true

  # make sure instance + volumes are ready
  depends_on = [
    aws_instance.this,
    aws_ebs_volume.all_volumes
  ]

  timeouts {
    create = "15m"
    delete = "15m"
  }
}
