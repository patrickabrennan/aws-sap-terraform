locals {
  # Normalize account id (works with either `account_id` or `Account_ID` in tfvars)
  effective_account_id = (
    try(length(trimspace(var.account_id)) > 0, false)
    ? trimspace(var.account_id)
    : trimspace(var.Account_ID)
  )

  # Common ARNs computed from inputs
  arn_ec2_instances_all     = "arn:aws:ec2:${var.aws_region}:${local.effective_account_id}:instance/*"
  arn_logs_group_sap_prefix = "arn:aws:logs:${var.aws_region}:${local.effective_account_id}:log-group:sap-logs:*"

  # If you truly have a fixed route table ID referenced by overlay IP:
  arn_overlayip_rtb         = "arn:aws:ec2:${var.aws_region}:${local.effective_account_id}:route-table/rtb-09728cc740c68d955"

  # ---------- TAGS ----------
  tags = {
    "owner"       = "AWS-SAP-ProServe"
    "environment" = var.environment
    "automation"  = "true"
    "criticality" = "essential"
    "ManagedBy"   = "Terraform"
    "GitRepo"     = "https://github.com/aws-samples/aws-sap-terraform"
  }

  # ---------- DYNAMIC (from SSM) ----------
  iam_dynamic_policy_statements = {
    efs = {
      name = "iam-policy-sap-efs"
      statements = {
        stmtd1 = {
          effect = "Allow"
          actions = [
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite",
            "elasticfilesystem:ClientRootAccess"
          ]
          resources = jsondecode(data.aws_ssm_parameter.sap_efs_list.value)
        }
      }
    },
    ec2_others = {
      name = "iam-policy-sap-ec2-others"
      statements = {
        stmtd2 = {
          effect = "Allow"
          actions = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:ReEncryptTo",
            "kms:DescribeKey",
            "kms:ReEncryptFrom",
          ]
          resources = jsondecode(data.aws_ssm_parameter.sap_kms_arn_list.value)
        }
      }
    }
  }

  # ---------- FIXUPS for tfvars that used ${var...} (which is literal in tfvars) ----------
  # We take your var.iam_policies and surgically replace the specific statements that
  # need region/account interpolation with correctly computed ARNs.
  iam_policies_fixed = merge(
    var.iam_policies,

    # pacemaker_overlayip: stmt1.resources -> route-table ARN
    try(
      {
        pacemaker_overlayip = merge(
          var.iam_policies.pacemaker_overlayip,
          {
            statements = merge(
              var.iam_policies.pacemaker_overlayip.statements,
              {
                stmt1 = merge(
                  var.iam_policies.pacemaker_overlayip.statements.stmt1,
                  { resources = [local.arn_overlayip_rtb] }
                )
              }
            )
          }
        )
      },
      {}
    ),

    # pacemaker_stonith: stmt2.resources -> all EC2 instances ARN
    try(
      {
        pacemaker_stonith = merge(
          var.iam_policies.pacemaker_stonith,
          {
            statements = merge(
              var.iam_policies.pacemaker_stonith.statements,
              {
                stmt2 = merge(
                  var.iam_policies.pacemaker_stonith.statements.stmt2,
                  { resources = [local.arn_ec2_instances_all] }
                )
              }
            )
          }
        )
      },
      {}
    ),

    # ec2_others: stmt2.resources -> CloudWatch/Logs group prefix ARN
    try(
      {
        ec2_others = merge(
          var.iam_policies.ec2_others,
          {
            statements = merge(
              var.iam_policies.ec2_others.statements,
              {
                stmt2 = merge(
                  var.iam_policies.ec2_others.statements.stmt2,
                  { resources = [local.arn_logs_group_sap_prefix] }
                )
              }
            )
          }
        )
      },
      {}
    )
  )

  # ---------- COMBINE USER + DYNAMIC ----------
  keys_iam_dynamic_policy_statements = keys(local.iam_dynamic_policy_statements)
  keys_iam_policies                  = keys(local.iam_policies_fixed)
  all_keys                           = distinct(concat(local.keys_iam_dynamic_policy_statements, local.keys_iam_policies))

  iam_combined_policies = {
    for k in local.all_keys :
    k => {
      name       = try(local.iam_policies_fixed[k].name, local.iam_dynamic_policy_statements[k].name),
      statements = merge(
        try(local.iam_policies_fixed[k].statements, {}),
        try(local.iam_dynamic_policy_statements[k].statements, {})
      )
    }...
  }
}











/*
locals {
  tags = {
    "owner"       = "AWS-SAP-ProServe"
    "environment" = var.environment
    "automation"  = "true"
    "criticality" = "essential"
    "ManagedBy"   = "Terraform"
    "GitRepo"     = "https://github.com/aws-samples/aws-sap-terraform"
  }

  iam_dynamic_policy_statements = {
    efs = {
      name = "iam-policy-sap-efs"
      statements = {
        stmtd1 = {
          effect = "Allow"
          actions = [
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite",
            "elasticfilesystem:ClientRootAccess"
          ]
          resources = jsondecode(data.aws_ssm_parameter.sap_efs_list.value)
        }
      }
    },
    ec2_others = {
      name = "iam-policy-sap-ec2-others"
      statements = {
        stmtd2 = {
          effect = "Allow"
          actions = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:ReEncryptTo",
            "kms:DescribeKey",
            "kms:ReEncryptFrom",
          ]
          resources = jsondecode(data.aws_ssm_parameter.sap_kms_arn_list.value)
        }
      }
    }
  }

  keys_iam_dynamic_policy_statements = keys(local.iam_dynamic_policy_statements)
  keys_iam_policies                  = keys(var.iam_policies)
  all_keys                           = distinct(concat(local.keys_iam_dynamic_policy_statements, local.keys_iam_policies))

  iam_combined_policies = {
    for k in local.all_keys :
    k => {
      name       = try(var.iam_policies[k].name, local.iam_dynamic_policy_statements[k].name),
      statements = merge(try(var.iam_policies[k].statements, {}), try(local.iam_dynamic_policy_statements[k].statements, {}))
    }...
  }
}
*/
