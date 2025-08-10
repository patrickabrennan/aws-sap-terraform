# SSH ingress rules for app1 and db1 security groups.
# This assumes the SG resources are named aws_security_group.app1 and .db1

# From CIDRs -> app1
resource "aws_vpc_security_group_ingress_rule" "app1_ssh_cidrs" {
  for_each          = toset(var.ssh_cidrs)
  security_group_id = aws_security_group.app1.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${each.value}"
}

# From CIDRs -> db1
resource "aws_vpc_security_group_ingress_rule" "db1_ssh_cidrs" {
  for_each          = toset(var.ssh_cidrs)
  security_group_id = aws_security_group.db1.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${each.value}"
}

# From source SGs (e.g., bastion) -> app1
resource "aws_vpc_security_group_ingress_rule" "app1_ssh_sg" {
  for_each                     = toset(var.ssh_source_security_group_ids)
  security_group_id            = aws_security_group.app1.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${each.value}"
}

# From source SGs (e.g., bastion) -> db1
resource "aws_vpc_security_group_ingress_rule" "db1_ssh_sg" {
  for_each                     = toset(var.ssh_source_security_group_ids)
  security_group_id            = aws_security_group.db1.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${each.value}"
}
