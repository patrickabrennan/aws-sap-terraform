output "sg_tags_all" {
  value = aws_security_group.this.tags
}

output "sg_id" {
  value = aws_security_group.this.id
}
