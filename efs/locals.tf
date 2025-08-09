locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.selected.id
  tags = {
    "owner"       = "AWS-SAP-ProServe"
    "environment" = var.environment
    "automation"  = "true"
    "criticality" = "essential"
    "ManagedBy"   = "Terraform"
    "GitRepo"     = "https://https://github.com/patrickabrennan/aws-sap-terraform"
    "environment"  = var.environment
    "sap_relevant" = "true"
  }
}
