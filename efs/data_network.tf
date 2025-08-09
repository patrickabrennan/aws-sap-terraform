data "aws_vpc" "selected" {
  tags = {
    Name         = "sap_vpc"
    sap_relevant = "true"
  }
}
