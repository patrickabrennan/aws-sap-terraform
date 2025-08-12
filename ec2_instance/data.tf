############################################
# Resolve a VPC: by ID, by Name tag, or by arbitrary tag
############################################

data "aws_vpcs" "by_name" {
  count = var.vpc_name != "" ? 1 : 0
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_vpcs" "by_tag" {
  count = (var.vpc_tag_key != "" && var.vpc_tag_value != "") ? 1 : 0
  filter {
    name   = "tag:${var.vpc_tag_key}"
    values = [var.vpc_tag_value]
  }
}

locals {
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

data "aws_vpc" "sap" {
  id         = local.vpc_id_effective
  depends_on = [null_resource.assert_vpc]
}
