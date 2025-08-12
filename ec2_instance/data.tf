############################################
# VPC resolution (choose by ID, Name tag, or arbitrary tag)
# Requires variables (declare in variables.tf):
#   - var.vpc_id        (string, default "")
#   - var.vpc_name      (string, default "")
#   - var.vpc_tag_key   (string, default "")
#   - var.vpc_tag_value (string, default "")
############################################

# Optional: match VPCs by Name tag
data "aws_vpcs" "by_name" {
  count = var.vpc_name != "" ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Optional: match VPCs by arbitrary tag key/value
data "aws_vpcs" "by_tag" {
  count = (var.vpc_tag_key != "" && var.vpc_tag_value != "") ? 1 : 0

  filter {
    name   = "tag:${var.vpc_tag_key}"
    values = [var.vpc_tag_value]
  }
}

locals {
  # Order of precedence: explicit vpc_id, then Name, then arbitrary tag
  vpc_candidates = compact(concat(
    var.vpc_id != "" ? [var.vpc_id] : [],
    var.vpc_name != "" ? try(data.aws_vpcs.by_name[0].ids, []) : [],
    (var.vpc_tag_key != "" && var.vpc_tag_value != "") ? try(data.aws_vpcs.by_tag[0].ids, []) : []
  ))

  vpc_id_effective = length(local.vpc_candidates) > 0 ? local.vpc_candidates[0] : ""
}

resource "null_resource" "assert_vpc" {
  lifecycle {
    precondition {
      condition     = local.vpc_id_effective != ""
      error_message = "Could not resolve a VPC. Set one of: vpc_id, vpc_name, or vpc_tag_key+vpc_tag_value."
    }
  }
}

# Final resolved VPC used by the rest of the root module
data "aws_vpc" "sap" {
  id = local.vpc_id_effective
}

############################################
# SSM lookups for security group IDs
# Requires: var.environment (string)
############################################

data "aws_ssm_parameter" "app1_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

data "aws_ssm_parameter" "db1_sg" {
  name = "/${var.environment}/security_group/db1/id"
}
