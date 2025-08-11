############################################
# Subnet discovery for INSTANCE (primary ENI)
############################################

# Only query when no explicit subnet_ID was given
data "aws_subnets" "primary" {
  count = var.subnet_ID == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # Optional: tag key/value
  dynamic "filter" {
    for_each = (var.subnet_tag_key != "" && var.subnet_tag_value != "") ? [1] : []
    content {
      name   = "tag:${var.subnet_tag_key}"
      values = [var.subnet_tag_value]
    }
  }

  # Optional: tag:Name wildcard
  dynamic "filter" {
    for_each = var.subnet_name_wildcard != "" ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.subnet_name_wildcard]
    }
  }
}

locals {
  # Candidate list (explicit ID wins)
  primary_candidates = var.subnet_ID != ""
    ? [var.subnet_ID]
    : try(data.aws_subnets.primary[0].ids, [])

  subnet_id_effective = (
    length(local.primary_candidates) == 1
      ? local.primary_candidates[0]
      : (
          length(local.primary_candidates) > 1 && var.subnet_selection_mode == "first"
            ? sort(local.primary_candidates)[0]
            : ""
        )
  )
}

# Helpful assertion when no single subnet selected
resource "null_resource" "assert_single_subnet" {
  triggers = { chosen = local.subnet_id_effective }

  lifecycle {
    precondition {
      condition = local.subnet_id_effective != ""
      error_message = "Subnet lookup did not resolve to a single subnet in ${var.vpc_id} / ${var.availability_zone}.\n" \
        "Refine selection by setting one of:\n" \
        " - subnet_tag_key + subnet_tag_value       (e.g., Tier=app)\n" \
        " - subnet_name_wildcard                    (e.g., \"*public*\" or \"*private*\")\n" \
        "Or allow auto-pick by setting:\n" \
        " - subnet_selection_mode = \"first\""
    }
  }
}

# Concrete subnet object for downstream references
data "aws_subnet" "effective" {
  count = local.subnet_id_effective != "" ? 1 : 0
  id    = local.subnet_id_effective
}
