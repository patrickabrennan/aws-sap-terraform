data "aws_vpc" "selected" {
  filter {
    #name   = "tag:${var.sap_discovery_tag}"
    name   = "tag:Name"
    values = ["sap_vpc"]
  }
  tags = {
    Name         = "sap_vpc"
    sap_relevant = "true"
  }
}
