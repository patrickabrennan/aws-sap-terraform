# KMS

Configuration of KMS resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

* [KMS Keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)
* [KMS Key Alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)
* [KMS Key Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy)

## Usage

Specify the list of KMS Keys to be created in the corresponding ENV.tfvars file following the example below. Check the detailed description for each variable in the section below.

## Dynamic configurations

* Key policies: There are two types of key policies to be applied to each of your keys. One of them is specific to EBS, granting required extra permissions for when the key is used with the Autoscaling service. The other is common, used for all the other scenarios, and doesn't require the extra permissions.

## Examples

```hcl
environment = "dev"
aws_region = "us-east-1"

keys_to_create = {
  "ebs" = {
    alias_name = "kms-alias-ebs"
  }
  "efs"        = {}
  "cloudwatch" = {}
  "s3"         = {}
}
```

Under ```keys_to_create``` you declare all the keys to be created. We recommend using the target service name as the key for the value (examples above are ebs, efs, cloudwatch and s3). That key name will be used to create the key alias. You can customize the key alias name by passing the variable "alias_name" in the configuration.

This example assumes you are using the pattern of having one KMS key per service that stores [data at rest](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/protecting-data-at-rest.html). If you are not following this pattern, feel free to give different values for your key names.

## Input variables

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|environment|Environment name|dev|Yes
|aws_region|Region where resources are being deployed|us-east-1|Yes
|keys_to_create|Map of keys to be created|Key-value map. The key (examples above are "ebs", "efs", "cloudwatch" and "s3") will be used as the KMS key name. See below for details|Yes

### ```keys_to_create``` variable details
| Name | Description | Example | Required |
|------|-------------|--------|--------|
|alias_name|Custom alias name for KMS alias resource|kms-alias-ebs-dev|No


## Parameters in AWS Systems Manager Parameter Store updated by this configuration

| Parameter | Example | Where-used |
|------|-------------|------------|
|/&lt;env&gt;/kms/sap/list|/dev/kms/sap/list|This parameter has a list of arn(s) for CMKs created through this configuration. The parameter is referenced during the definition of the IAM policies that authorize the use of the CMKs|
|/&lt;env&gt;/kms/&lt;service&gt;/arn|/dev/kms/efs/arn|ARN of the created KMS key
|/&lt;env&gt;/kms/&lt;service&gt;/alias|/dev/kms/efs/alias|Alias of the created KMS key
