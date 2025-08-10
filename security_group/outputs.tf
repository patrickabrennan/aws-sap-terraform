# modules/security_group/outputs.tf
# Export the SG ID created by this module invocation.
# This assumes your SG resource inside the module is named `aws_security_group.this`.
# If it’s named differently, adjust the reference accordingly.

output "security_group_id" {
  description = "ID of the security group created by this module"
  value       = aws_security_group.this.id
}
