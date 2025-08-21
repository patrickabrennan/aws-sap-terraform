#BEGIN NEW LOCAL.TF File @ 3:43PM 
#commented out 8/21/2025
#locals {
#  # --- ACCOUNT ID NORMALIZATION ---
#  # Supports either `account_id` or legacy `Account_ID` from tfvars
#  effective_account_id = (
#    try(length(trimspace(var.account_id)) > 0, false)
#    ? trimspace(var.account_id)
#    : trimspace(var.Account_ID)
#  )
#end comment out 8/21/25
locals {
  # --- ACCOUNT ID NORMALIZATION (dynamic, with overrides) ---
  # 1) If var.account_id is set, use it
  # 2) else if legacy var.Account_ID is set, use it
  # 3) else use the live account from the provider creds
  effective_account_id = coalesce(
    try(length(trimspace(var.account_id))  > 0 ? trimspace(var.account_id)  : null, null),
    try(length(trimspace(var.Account_ID)) > 0 ? trimspace(var.Account_ID) : null, null),
    data.aws_caller_identity.current.account_id
  )

  # --- TAGS ---
  tags = {
    "owner"       = "AWS-SAP-ProServe"
    "environment" = var.environment
    "automation"  = "true"
    "criticality" = "essential"
    "ManagedBy"   = "Terraform"
    "GitRepo"     = "https://github.com/aws-samples/aws-sap-terraform"
  }

  # --- DYNAMIC STATEMENTS (from SSM) ---
  # Keep as-is from your original file
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

  # --- SANITIZE tfvars (replace placeholders with real values) ---
  # In dev.auto.tfvars, use __REGION__ and __ACCOUNT_ID__ instead of ${var...}
  # Example:
  #   arn:aws:ec2:__REGION__:__ACCOUNT_ID__:instance/*
  #   arn:aws:ec2:__REGION__:__ACCOUNT_ID__:route-table/rtb-...
  #   arn:aws:logs:__REGION__:__ACCOUNT_ID__:log-group:sap-logs:*
  iam_policies_sanitized = jsondecode(
    replace(
      replace(
        jsonencode(var.iam_policies),
        "__REGION__",
        var.aws_region
      ),
      "__ACCOUNT_ID__",
      local.effective_account_id
    )
  )

  # --- COMBINE USER (sanitized) + DYNAMIC ---
  keys_iam_dynamic_policy_statements = keys(local.iam_dynamic_policy_statements)
  keys_iam_policies                  = keys(local.iam_policies_sanitized)
  all_keys                           = distinct(
    concat(local.keys_iam_dynamic_policy_statements, local.keys_iam_policies)
  )

  iam_combined_policies = {
    for k in local.all_keys :
    k => {
      name = try(
        local.iam_policies_sanitized[k].name,
        local.iam_dynamic_policy_statements[k].name
      )
      statements = merge(
        try(local.iam_policies_sanitized[k].statements, {}),
        try(local.iam_dynamic_policy_statements[k].statements, {})
      )
    }...
  }
}
#END NEW LOCAL.TF File @ 3:43PM 









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
