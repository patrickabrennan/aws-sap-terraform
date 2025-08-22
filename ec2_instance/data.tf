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

#added 8/22/2025
resource "null_resource" "assert_two_azs" {
  lifecycle {
    precondition {
      condition     = length(local.azs_with_subnets) >= 2
      error_message = "Need subnets (matching your filters) in at least 2 AZs of VPC ${data.aws_vpc.sap.id}."
    }
  }
}
#end commnet out 8/22/2025



data "aws_vpc" "sap" {
  id         = local.vpc_id_effective
  depends_on = [null_resource.assert_vpc]
}

############################################
# Auto AZ + Subnet discovery (root workspace)
############################################

# All available AZs in the provider region
data "aws_availability_zones" "this" {
  state = "available"
}

# Keep a stable, sorted list of AZs
locals {
  azs_sorted = sort(data.aws_availability_zones.this.names)
}

# For each AZ, find candidate subnets in the resolved VPC
data "aws_subnets" "by_az" {
  for_each = toset(local.azs_sorted)

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sap.id]
  }

  filter {
    name   = "availability-zone"
    values = [each.value]
  }

  # Optional narrowing: tag filter
  dynamic "filter" {
    for_each = (try(var.subnet_tag_key, "") != "" && try(var.subnet_tag_value, "") != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional narrowing: Name wildcard
  dynamic "filter" {
    for_each = try(var.subnet_name_wildcard, "") != "" ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

# Pick one subnet per AZ: 'unique' => error if >1; 'first' => take the first
locals {
  subnet_id_by_az = {
    for az, ds in data.aws_subnets.by_az :
    az => (
      try(var.subnet_selection_mode, "unique") == "first"
      ? try(sort(ds.ids)[0], null)
      : (
          length(ds.ids) == 1
          ? ds.ids[0]
          : (
              length(ds.ids) == 0 ? null :
              (throw("Multiple subnets matched in AZ ${az}; set subnet_selection_mode = \"first\" or narrow filters"))
            )
        )
    )
  }
}

#added 8/22/2025
# after local.subnet_id_by_az
locals {
  azs_with_subnets = [
    for az in local.azs_sorted : az
    if try(local.subnet_id_by_az[az] != null && local.subnet_id_by_az[az] != "", false)
  ]
}
