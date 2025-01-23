output "efs" {
  value = aws_efs_file_system.this
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "arn" {
  value = aws_efs_file_system.this.arn
}
