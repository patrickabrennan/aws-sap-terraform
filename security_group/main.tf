########################################
# security_group/main.tf
########################################

module "app_security_groups" {
  for_each = var.app_sg_list
  source   = "./modules/security_group"

  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = data.aws_vpc.selected.id

  name         = each.key
  description  = each.value["description"]
  rules        = each.value["rules"]
  efs_to_allow = each.value["efs_to_allow"]

  tags = local.tags
}

module "db_security_groups" {
  for_each = var.db_sg_list
  source   = "./modules/security_group"

  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = data.aws_vpc.selected.id

  name                       = each.key
  description                = each.value["description"]
  rules                      = each.value["rules"]
  efs_to_allow               = each.value["efs_to_allow"]
  dependency_security_groups = module.app_security_groups

  tags = local.tags
}

# Build maps of SG IDs keyed by SG name (using module outputs)
locals {
  app_sg_ids = { for k, m in module.app_security_groups : k => m.sg_id }
  db_sg_ids  = { for k, m in module.db_security_groups  : k => m.sg_id }
}

# ---------------- SSH from CIDRs -> APP SGs ----------------
resource "aws_vpc_security_group_ingress_rule" "app_ssh_cidrs" {
  for_each = {
    for pair in setproduct(keys(local.app_sg_ids), var.ssh_cidrs) :
    "${pair[0]}|${pair[1]}" => {
      sg_id = local.app_sg_ids[pair[0]]
      cidr  = pair[1]
    }
  }

  security_group_id = each.value.sg_id
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${each.value.cidr}"
}

# ---------------- SSH from CIDRs -> DB SGs ----------------
resource "aws_vpc_security_group_ingress_rule" "db_ssh_cidrs" {
  for_each = {
    for pair in setproduct(keys(local.db_sg_ids), var.ssh_cidrs) :
    "${pair[0]}|${pair[1]}" => {
      sg_id = local.db_sg_ids[pair[0]]
      cidr  = pair[1]
    }
  }

  security_group_id = each.value.sg_id
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from CIDR ${each.value.cidr}"
}

# -------- SSH from source SGs (e.g., bastion) -> APP SGs --------
resource "aws_vpc_security_group_ingress_rule" "app_ssh_sg" {
  for_each = {
    for pair in setproduct(keys(local.app_sg_ids), var.ssh_source_security_group_ids) :
    "${pair[0]}|${pair[1]}" => {
      sg_id     = local.app_sg_ids[pair[0]]
      source_sg = pair[1]
    }
  }

  security_group_id            = each.value.sg_id
  referenced_security_group_id = each.value.source_sg
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${each.value.source_sg}"
}

# -------- SSH from source SGs (e.g., bastion) -> DB SGs --------
resource "aws_vpc_security_group_ingress_rule" "db_ssh_sg" {
  for_each = {
    for pair in setproduct(keys(local.db_sg_ids), var.ssh_source_security_group_ids) :
    "${pair[0]}|${pair[1]}" => {
      sg_id     = local.db_sg_ids[pair[0]]
      source_sg = pair[1]
    }
  }

  security_group_id            = each.value.sg_id
  referenced_security_group_id = each.value.source_sg
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from SG ${each.value.source_sg}"
}

# Existing EFS rule propagation (unchanged)
module "additional_rules_for_efs" {
  for_each = merge(module.app_security_groups, module.db_security_groups)
  source   = "./modules/additional_rules_for_existing_sg"

  environment  = var.environment
  sgs_to_allow = each.value.efs_to_allow
  sg_source    = each.value.sg_id
}
