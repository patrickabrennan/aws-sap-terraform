# Pick exactly ONE subnet in the given VPC and AZ
data "aws_subnets" "by_filters" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

locals {
  # Ensure exactly one subnet (adjust your VPC setup/tags if this fails)
  subnet_id_effective = (
    length(data.aws_subnets.by_filters.ids) == 1
    ? data.aws_subnets.by_filters.ids[0]
    : ""
  )
}

resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = "Subnet lookup did not resolve to exactly one subnet in ${var.vpc_id} / ${var.availability_zone}. Refine your subnets."
    }
  }
}

data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}






/*
# --- SSM parameters used by the module ---

data "aws_ssm_parameter" "ebs_kms" {
  name = "/${var.environment}/kms/ebs/arn"
}

data "aws_ssm_parameter" "ec2_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2-ha/name"
}

data "aws_ssm_parameter" "ec2_non_ha_instance_profile" {
  name = "/${var.environment}/iam/role/instance-profile/iam-role-sap-ec2/name"
}

data "aws_ssm_parameter" "ec2_hana_sg" {
  name = "/${var.environment}/security_group/db1/id"
}

data "aws_ssm_parameter" "ec2_nw_sg" {
  name = "/${var.environment}/security_group/app1/id"
}

# --- Subnet discovery (no subnet_ID var) ---
# Require vpc_id + availability_zone + tag filters to resolve exactly one subnet.

data "aws_subnets" "by_filters" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }

  # One filter per tag key/value provided to the module.
  dynamic "filter" {
    for_each = var.subnet_tag_filters
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

#locals {
#  subnet_id_effective = length(data.aws_subnets.by_filters.ids) == 1
#    ? data.aws_subnets.by_filters.ids[0]
#    : ""
#}
locals {
  subnet_id_effective = (
    length(data.aws_subnets.by_filters.ids) == 1
    ? data.aws_subnets.by_filters.ids[0]
    : ""
  )
}


# Fail fast if the lookup is not unique (0 or >1).
resource "null_resource" "assert_single_subnet" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_effective != ""
      error_message = "Subnet lookup did not resolve to exactly one subnet. Check availability_zone and subnet_tag_filters."
    }
  }
}

# Resolved subnet object (used for AZ, etc.).
data "aws_subnet" "effective" {
  id = local.subnet_id_effective
}
*/
