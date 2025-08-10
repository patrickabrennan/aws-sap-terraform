 resource "aws_ebs_volume" "all_volumes" {
  for_each = local.disks_by_key

  availability_zone = data.aws_subnet.effective.availability_zone
  size              = each.value.size
  type              = each.value.type
  encrypted         = true
  kms_key_id        = data.aws_ssm_parameter.ebs_kms.value

  # Only set iops/throughput when meaningful
  iops       = (contains(["io1","io2","gp3"], each.value.type) && each.value.iops > 0) ? each.value.iops : null
  throughput = (each.value.type == "gp3" && each.value.throughput > 0) ? each.value.throughput : null

  tags = merge(var.ec2_tags, {
    Name         = "${var.hostname}-${each.value.name}-${each.value.disk_index}"
    environment  = var.environment
    purpose      = each.value.name
    disk_index   = tostring(each.value.disk_index)
    attach_index = tostring(each.value.attach_index)
  })
}

resource "aws_volume_attachment" "all_attachments" {
  for_each    = local.disks_by_key
  device_name = local.device_names[min(each.value.attach_index, length(local.device_names) - 1)]
  volume_id   = aws_ebs_volume.all_volumes[each.key].id
  instance_id = aws_instance.this.id
}







#resource "aws_ebs_volume" "all_volumes" {
#  for_each = local.disks_by_key

#  availability_zone = data.aws_subnet.effective.availability_zone
#  size              = each.value.size
#  type              = each.value.type
#  encrypted         = true
#  kms_key_id        = data.aws_ssm_parameter.ebs_kms.value

#  tags = merge(var.ec2_tags, {
#    Name        = "${var.hostname}-${each.value.name}-${each.value.disk_index}"
#    environment = var.environment
#    purpose     = each.value.name
#    disk_index  = tostring(each.value.disk_index)
#  })
#}

#resource "aws_volume_attachment" "all_attachments" {
#  for_each    = local.disks_by_key
#  device_name = local.device_names[min(each.value.disk_index, length(local.device_names) - 1)]
#  volume_id   = aws_ebs_volume.all_volumes[each.key].id
#  instance_id = aws_instance.this.id  # change this if your instance resource name differs
#}









#resource "aws_ebs_volume" "all_volumes" {
#  for_each = { for idx, val in local.all_disks : join(".", [val.identifier, val.disk_index]) => val }

#  availability_zone = data.aws_subnet.effective.availability_zone
#  #availability_zone = data.aws_subnet.selected.availability_zone
#  size              = each.value["disk_size"]
#  type              = each.value["disk_type"]
#  iops              = contains(["gp2", "st1", "sc1"], each.value["disk_type"]) ? null : each.value["iops"]
#  throughput        = contains(["gp3"], each.value["disk_type"]) ? each.value["throughput"] : null

#  kms_key_id = data.aws_ssm_parameter.ebs_kms.value
#  encrypted  = true

#  tags = {
#    Name             = "ebs-${var.hostname}"
#    disk-identifier  = each.value.identifier
#    disk-index       = each.value.disk_index
#    device-name      = local.device_name[each.value.identifier][each.value.disk_index]
#    path_to_mount    = local.os_path_to_mount[each.value.identifier]
#    application-code = var.application_code
#    sid              = var.application_SID
#    backup-policy    = each.value["identifier"]
#  }

#}

#resource "aws_volume_attachment" "ebs_attach_data_volumes" {
#  for_each = aws_ebs_volume.all_volumes

#  device_name = local.device_name[each.value.tags["disk-identifier"]][each.value.tags["disk-index"]]
#  instance_id = aws_instance.this.id
#  volume_id   = aws_ebs_volume.all_volumes[each.key].id
#}
