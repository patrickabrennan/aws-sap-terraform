# -------------------------------
# Primary ENI subnet auto-select
# -------------------------------
data "aws_subnets" "by_filters" {
  count = var.subnet_ID == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional tag key/value filter (exact match)
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional Name wildcard (EC2 supports '*' wildcards in filter values)
  dynamic "filter" {
    for_each = (var.subnet_name_wildcard != "") ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  # Candidate IDs when not explicitly provided
  _primary_candidates = var.subnet_ID != ""
    ? [var.subnet_ID]
    : (
        length(data.aws_subnets.by_filters) == 1
        ? data.aws_subnets.by_filters[0].ids
        : []
      )

  subnet_id_effective = (
    length(local._primary_candidates) == 1
      ? local._primary_candidates[0]
      : (
          var.subnet_selection_mode == "first" && length(local._primary_candidates) > 1
          ? sort(local._primary_candidates)[0]
          : ""
        )
  )
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition = local.subnet_id_effective != ""
      error_message = <<EOM
Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.
Try one of:
 - set var.subnet_tag_key/var.subnet_tag_value to narrow by tag
 - set var.subnet_name_wildcard (e.g. "*public*" or "*private*")
 - or set var.subnet_selection_mode = "first" to pick the first after sorting IDs
EOM
    }
  }
}

data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}
