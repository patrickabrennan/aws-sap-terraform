environment = "dev"
aws_region  = "us-east-1"

iam_roles = {
  role1 = {
    name = "iam-role-sap-ec2"
        assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = "arn:aws:iam::285942769742:policy/example-permissions-boundary-rds"
  },
  role2 = {
    name = "iam-role-sap-ec2-ha"
    assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others",
      "iam-policy-sap-pacemaker-stonith",
      "iam-policy-sap-pacemaker-overlayip"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = ""
  }
}

iam_policies = {
  data_provider = {
    name = "iam-policy-sap-data-provider"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        resources = ["*"]
      },
      stmt2 = {
        effect    = "Allow"
        actions   = ["cloudwatch:GetMetricStatistics"]
        resources = ["*"]
      },
      stmt3 = {
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["arn:aws:s3:::aws-data-provider/config.properties"]
      }
    }
  },
  pacemaker_overlayip = {
    name = "iam-policy-sap-pacemaker-overlayip"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:ReplaceRoute",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:route-table/rtb-09728cc740c68d955"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRouteTables",
        ]
        resources = ["*"]
      }
    }
  }
  pacemaker_stonith = {
    name = "iam-policy-sap-pacemaker-stonith"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeTags",
        ]
        resources = ["*"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:ModifyInstanceAttribute",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:instance/*"]
      }
    }
  },
  ec2_others = {
    name = "iam-policy-sap-ec2-others"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutObjectTagging",
          "s3:PutObject",
          "s3:GetObject",
          "s3:HeadObject",
          "s3:DeleteObject",
        ]
        resources = ["arn:aws:s3:::sap-media-bucket"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "cloudwatch:ListTagsForResource",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetDashboard",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "logs:TagLogGroup"
        ]
        resources = ["arn:aws:logs:us-east-1:285942769742:log-group:sap-logs:*"]
      }
    }
  }
}








/*
environment = "dev"
aws_region  = "us-east-1"

iam_roles = {
  role1 = {
    name = "iam-role-sap-ec2"
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = "arn:aws:iam::285942769742:policy/example-permissions-boundary-rds"
  },
  role2 = {
    name = "iam-role-sap-ec2-ha"
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others",
      "iam-policy-sap-pacemaker-stonith",
      "iam-policy-sap-pacemaker-overlayip"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = ""
  }
}

iam_policies = {
  data_provider = {
    name = "iam-policy-sap-data-provider"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        resources = ["*"]
      },
      stmt2 = {
        effect    = "Allow"
        actions   = ["cloudwatch:GetMetricStatistics"]
        resources = ["*"]
      },
      stmt3 = {
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["arn:aws:s3:::aws-data-provider/config.properties"]
      }
    }
  },
  pacemaker_overlayip = {
    name = "iam-policy-sap-pacemaker-overlayip"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:ReplaceRoute",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:route-table/rtb-09728cc740c68d955"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRouteTables",
        ]
        resources = ["*"]
      }
    }
  }
  pacemaker_stonith = {
    name = "iam-policy-sap-pacemaker-stonith"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeTags",
        ]
        resources = ["*"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:ModifyInstanceAttribute",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
        ]
        resources = ["arn:aws:ec2::us-east-1:285942769742:instance/*"]
      }
    }
  },
  ec2_others = {
    name = "iam-policy-sap-ec2-others"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutObjectTagging",
          "s3:PutObject",
          "s3:GetObject",
          "s3:HeadObject",
          "s3:DeleteObject",
        ]
        resources = ["arn:aws:s3:::sap-media-bucket"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "cloudwatch:ListTagsForResource",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetDashboard",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "logs:TagLogGroup"
        ]
        resources = ["arn:aws:logs:us-east-1:285942769742:log-group:sap-logs:*"]
      }
    }
  }
}
*/



/*
environment = "dev"
aws_region  = "us-east-1"

iam_roles = {
  role1 = {
    name = "iam-role-sap-ec2"
    #assume_role_policy = jsonencode({
    #  Version = "2012-10-17"
    #  Statement = [{
    #    Effect = "Allow"
    #    Principal = {
    #      Service = "ec2.amazonaws.com"
    #    }
    #    Action = "sts:AssumeRole"
    #  }]
    #})
    assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
         }
       ]
      }
      EOF
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = "arn:aws:iam::285942769742:policy/example-permissions-boundary-rds"
  },
  role2 = {
    name = "iam-role-sap-ec2-ha"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }]
    })
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others",
      "iam-policy-sap-pacemaker-stonith",
      "iam-policy-sap-pacemaker-overlayip"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = ""
  }
}

iam_policies = {
  data_provider = {
    name = "iam-policy-sap-data-provider"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        resources = ["*"]
      },
      stmt2 = {
        effect    = "Allow"
        actions   = ["cloudwatch:GetMetricStatistics"]
        resources = ["*"]
      },
      stmt3 = {
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["arn:aws:s3:::aws-data-provider/config.properties"]
      }
    }
  },
  pacemaker_overlayip = {
    name = "iam-policy-sap-pacemaker-overlayip"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:ReplaceRoute",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:route-table/rtb-09728cc740c68d955"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRouteTables",
        ]
        resources = ["*"]
      }
    }
  }
  pacemaker_stonith = {
    name = "iam-policy-sap-pacemaker-stonith"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeTags",
        ]
        resources = ["*"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:ModifyInstanceAttribute",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:instance/*"]
      }
    }
  },
  ec2_others = {
    name = "iam-policy-sap-ec2-others"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutObjectTagging",
          "s3:PutObject",
          "s3:GetObject",
          "s3:HeadObject",
          "s3:DeleteObject",
        ]
        resources = ["arn:aws:s3:::sap-media-bucket"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "cloudwatch:ListTagsForResource",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetDashboard",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "logs:TagLogGroup"
        ]
        resources = ["arn:aws:logs:us-east-1:285942769742:log-group:sap-logs:*"]
      }
    }
  }
}









environment = "dev"
aws_region  = "us-east-1"

iam_roles = {
  role1 = {
    name = "iam-role-sap-ec2"
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = "arn:aws:iam::285942769742:policy/example-permissions-boundary-rds"
  },
  role2 = {
    name = "iam-role-sap-ec2-ha"
    policies = [
      "iam-policy-sap-data-provider",
      "iam-policy-sap-efs",
      "iam-policy-sap-ec2-others",
      "iam-policy-sap-pacemaker-stonith",
      "iam-policy-sap-pacemaker-overlayip"
    ]
    managed_policies = [
      "AmazonSSMManagedInstanceCore"
    ]
    permissions_boundary_arn = ""
  }
}

iam_policies = {
  data_provider = {
    name = "iam-policy-sap-data-provider"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        resources = ["*"]
      },
      stmt2 = {
        effect    = "Allow"
        actions   = ["cloudwatch:GetMetricStatistics"]
        resources = ["*"]
      },
      stmt3 = {
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["arn:aws:s3:::aws-data-provider/config.properties"]
      }
    }
  },
  pacemaker_overlayip = {
    name = "iam-policy-sap-pacemaker-overlayip"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:ReplaceRoute",
        ]
        resources = ["arn:aws:ec2:us-east-1:285942769742:route-table/rtb-09728cc740c68d955"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRouteTables",
        ]
        resources = ["*"]
      }
    }
  }
  pacemaker_stonith = {
    name = "iam-policy-sap-pacemaker-stonith"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeTags",
        ]
        resources = ["*"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "ec2:ModifyInstanceAttribute",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
        ]
        resources = ["arn:aws:ec2::us-east-1:285942769742:instance/*"]
      }
    }
  },
  ec2_others = {
    name = "iam-policy-sap-ec2-others"
    statements = {
      stmt1 = {
        effect = "Allow"
        actions = [
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutObjectTagging",
          "s3:PutObject",
          "s3:GetObject",
          "s3:HeadObject",
          "s3:DeleteObject",
        ]
        resources = ["arn:aws:s3:::sap-media-bucket"]
      }
      stmt2 = {
        effect = "Allow"
        actions = [
          "cloudwatch:ListTagsForResource",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetDashboard",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "logs:TagLogGroup"
        ]
        resources = ["arn:aws:logs:us-east-1:285942769742:log-group:sap-logs:*"]
      }
    }
  }
}
*/
