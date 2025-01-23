resource "aws_security_group" "this" {
  name        = "${var.environment}_${var.sg_name}"
  description = "Security group ${var.environment}_${var.sg_name}"
  vpc_id      = var.vpc
  tags        = var.tags
}
