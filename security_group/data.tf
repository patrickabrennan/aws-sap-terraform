data "aws_vpc" "selected" {
  filter {
    name = "sap_vpc
    #name   = "tag:${var.sap_discovery_tag}"
    #values = ["*"]
  }
}
