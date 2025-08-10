# SSH from CIDRs -> app1
resource "aws_vpc_security_group_ingress_rule" "app1_ssh_cidrs" {
  count             = var.manage_app1 ? length(var.ssh_cidrs) : 0
  security_group_id = aws_security_group.app1.id
  cidr_ipv4         = var.ssh_cidrs[count.index]
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${var.ssh_cidrs[count.index]}"
}

# SSH from CIDRs -> db1
resource "aws_vpc_security_group_ingress_rule" "db1_ssh_cidrs" {
  count             = var.manage_db1 ? length(var.ssh_cidrs) : 0
  security_group_id = aws_security_group.db1.id
  cidr_ipv4         = var.ssh_cidrs[count.index]
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${var.ssh_cidrs[count.index]}"
}

# SSH from source SGs (e.g., bastion) -> app1
resource "aws_vpc_security_group_ingress_rule" "app1_ssh_sg" {
  count                        = var.manage_app1 ? length(var.ssh_source_security_group_ids) : 0
  security_group_id            = aws_security_group.app1.id
  referenced_security_group_id = var.ssh_source_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${var.ssh_source_security_group_ids[count.index]}"
}

# SSH from source SGs (e.g., bastion) -> db1
resource "aws_vpc_security_group_ingress_rule" "db1_ssh_sg" {
  count                        = var.manage_db1 ? length(var.ssh_source_security_group_ids) : 0
  security_group_id            = aws_security_group.db1.id
  referenced_security_group_id = var.ssh_source_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${var.ssh_source_security_group_ids[count.index]}"
}
