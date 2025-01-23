data "aws_vpc" "selected" {
  filter {
    name   = "tag:${var.sap_discovery_tag}"
    values = ["*"]
  }
}
