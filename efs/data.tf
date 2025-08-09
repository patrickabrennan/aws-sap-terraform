data "aws_vpc" "selected" {
  filter {
    name   = "tag:${var.sap_discovery_tag}"
    values = ["*"]
  }
  tags = {
    Name         = "sap_vpc"
    sap_relevant = "true"
    environment  = var.environment
  }
}
