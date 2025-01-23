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
