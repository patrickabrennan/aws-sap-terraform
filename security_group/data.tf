data "aws_vpc" "selected" {
  filter {
    id = var.vpc_id
#    name = "tag:sap_vpc"
#    #name   = "tag:${var.sap_discovery_tag}"
#    values = ["*"]
  }
}
