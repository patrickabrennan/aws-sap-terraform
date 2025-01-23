resource "aws_security_group_rule" "this" {
  for_each = var.rules

  type              = "ingress"
  from_port         = each.value["ports"][0]
  to_port           = length(each.value["ports"]) > 1 ? each.value["ports"][1] : each.value["ports"][0]
  protocol          = try(each.value["protocol"], "tcp")
  security_group_id = aws_security_group.this.id
  description       = try(each.value["description"])

  cidr_blocks              = each.value["source"] == "vpc" ? [data.aws_vpc.vpc.cidr_block] : null
  self                     = each.value["source"] == "self" ? true : null
  source_security_group_id = (each.value["source"] != "vpc" && each.value["source"] != "self") ? var.dependency_security_groups[each.value["source"]].sg_id : null
}
