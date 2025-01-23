resource "aws_efs_file_system" "this" {
  creation_token = "${var.environment}-${var.sid_filesystem_to_create}-sap-efs"
  encrypted      = true
  kms_key_id     = data.aws_ssm_parameter.kms_for_efs.value
  tags = merge(var.tags, {
    Name                       = "${var.environment}-${var.sid_filesystem_to_create}-sap-efs",
    "${var.sap_discovery_tag}" = "yes"
  })
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  root_directory {
    creation_info {
      owner_gid   = var.access_point_info["root_directory"]["creation_info"]["owner_gid"]
      owner_uid   = var.access_point_info["root_directory"]["creation_info"]["owner_uid"]
      permissions = var.access_point_info["root_directory"]["creation_info"]["permissions"]
    }
    path = var.access_point_info["root_directory"]["path"]
  }
  posix_user {
    uid = var.access_point_info["posix_user"]["uid"]
    gid = var.access_point_info["posix_user"]["gid"]
  }
  tags = merge(var.tags, {
    "${var.sap_discovery_tag}" = "yes"
  })
}
