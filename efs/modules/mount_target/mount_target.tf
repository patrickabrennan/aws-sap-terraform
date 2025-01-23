resource "aws_efs_mount_target" "this" {
  count           = length(data.aws_subnets.selected.ids)
  file_system_id  = var.efs_id
  subnet_id       = data.aws_subnets.selected.ids[count.index]
  security_groups = var.sg_id
}
