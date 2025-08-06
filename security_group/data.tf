#data "aws_vpc" "selected" {
#  filter {
#    name = "tag:sap_vpc"
#    #name   = "tag:${var.sap_discovery_tag}"
#    values = ["*"]
#  }
#}
vpc_id = var.vpc_id
