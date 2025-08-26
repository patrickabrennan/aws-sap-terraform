# IAM

Configuration of IAM resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

* [IAM Roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
* [IAM Policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)

## Usage: IAM Policies

Specify the IAM Policies to be created in the corresponding sap.auto.tfvars file following the example below. Check the detailed description for each variable in the subsequent sections below.

For better pipeline automation, there are cases where IAM Policies may have to reference ARNs of resources created by other parts of this solution. In that case, it is not possible to dynamically declare these references in the sap.auto.tfvars file. These dynamic references are handled separately in the locals.tf.

### Example - IAM Policy

The sap.auto.tfvars file will be used for declaring the static Permission Policy statements: 

```hcl
iam_policies = {
  ec2_permissions = {
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
    }
  }
}
```

As shown above, under ```iam_policies``` you declare all the IAM Policies to be created. Check the detailed description for each key pair value in the sections below.


Be noted that policy name (defined by "name") is configured to be the same in the ENV.tfvars (static permission policies) and locals.tf (dynamic permission policies). This will result in the permission policies from both files to be merged under a single policy during deployment. In order for the statements from one file not to override the other, the statement identificator should be different (for example, statement ID "stmt1" shown in the above sample policy, should not conflict with any statement IDs in locals.tf)


## Usage: IAM Roles

Specify the IAM Roles to be created in the corresponding sap.auto.tfvars file following the example below. Here you also specify what IAM Policies will be part of the IAM Role. Check the detailed description for each variable in the sections below.


### Example - IAM Role

```hcl
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
    permissions_boundary_arn = "arn:aws:iam::<<account nr>>:policy/example-permissions-boundary-rds"
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


```

Under ```iam_roles``` you declare all the roles to be created. Check the detailed description for each key pair value in the sections below.
</br></br>


## Regarding the input variables below, this repo defines environment and aws_region in the project variable set as they are needed in other workspaces. The iam_roles and iam_policies are defined in the sap.auto.tfvars file.


## Input variables

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|environment|Environment name|dev|Yes
|aws_region|Region where resources are being deployed|us-east-1|Yes
|iam_roles|Map of roles to be created|Key-value map. In the example above, keys "role1" and role2" are used to define the attributes of the 2 roles. See below for details on these attributes|Yes
|iam_policies|Map of policies to be created|Key-value map. In the example above, key "ec2_permissions" is used to define the attributes of the an IAM policy. See below for details on these attributes|Yes


### ```iam_policies``` variable details

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|name|Name of the IAM policy|iam-policy-sap-ec2-others|Yes
|statements|A key-value map with the IAM policy statements|Refer "stmt1" in the policy sample provided above |Yes

### ```iam_roles``` variable details

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|name|Name of the IAM role|iam-role-sap-ec2|Yes
|policies|List of IAM policies to be assigned to the IAM role |["iam-policy-sap-data-provider","iam-policy-sap-efs","iam-policy-sap-ec2-others"]|No
|managed_policies|List of AWS-managed policies to be assigned to the IAM role |["AmazonSSMManagedInstanceCore"]|No
|permissions_boundary_arn|Arn of IAM policy to be attached as IAM role's permission boundary |["AmazonSSMManagedInstanceCore"]|No


