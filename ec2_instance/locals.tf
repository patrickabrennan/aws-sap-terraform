locals {
  tags = {
    "owner"       = "AWS-SAP-ProServe"
    "environment" = var.environment
    "automation"  = "true"
    "criticality" = "essential"
    "ManagedBy"   = "Terraform"
    "GitRepo"     = "https://github.com/patrickabrennan/aws-sap-terraform"
    "sap_relevant" = "true"
  }
  # If a host omits subnet_ID, default to first discovered public subnet
  instances_to_create_normalized = {
    for k, v in var.instances_to_create :
    k => merge(v, {
      subnet_ID = try(v.subnet_ID, local.public_subnet_ids[0])
    })
  }
}
