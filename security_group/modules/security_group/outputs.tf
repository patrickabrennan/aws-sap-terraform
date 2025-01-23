output "sg_id" {
  value = aws_security_group.this.id
}

output "efs_to_allow" {
  value = var.efs_to_allow
}
