# EFS

Configuration of EFS resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

* [EFS File System](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system)
* [EFS Access Point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point)
* [EFS Mount Target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target)
* [Security Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html)
* [Security Group Rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)

## Usage

Specify the list of EFS File Systems to be created in the corresponding sap.auto.tfvars file following the example below. Check the detailed description for each variable in the section below.

## Examples

```hcl
efs_to_create = {
  "D01-sapmnt" = {
    access_point_info = {
      posix_user = {
        gid = 5001,
        uid = 3001
      },
      root_directory = {
        creation_info = {
          owner_gid   = 5001,
          owner_uid   = 3001,
          permissions = 0775
        },
        path : "/",
      }
    }
  }
}
```

Under ```efs_to_create``` you declare all the file systems to be created.


## Regarding the input variables below, this repo defines environment, aws_region, and sap_discovery_tag in the project variable set as they are needed in other workspaces. The efs_to_create are defined in the sap.auto.tfvars file.


## Input variables

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|environment|Environment name|dev|Yes
|aws_region|Region where resources are being deployed|us-east-1|Yes
|sap_discovery_tag|SAP discovery tag on existing subnets|sap_relevant|Yes
|efs_to_create|Map of EFS to be created|Key-value map. The key (example above is "D01-sapmnt") will be used for the EFS name. See below for details|Yes

### ```efs_to_create``` variable details
| Name | Description | Example | Required |
|------|-------------|--------|--------|
|access_point_info-posix_user-gid|Group id for the access point|5001|Yes
|access_point_info-posix_user-uid|User id for the access point|5001|Yes
|access_point_info-root_directory-creation_info-owner_gid|Owner group id for the root directory|5001|Yes
|access_point_info-root_directory-creation_info-owner_uid|Owner user id for the root directory|3001|Yes
|access_point_info-root_directory-creation_info-permissions|Permissions for the root directory|0775|Yes
|access_point_info-root_directory-path|Path in the EFS to use as root directory for the mount points|/|Yes

## Parameters created by this configuration

| Parameter | Example | Where-used |
|------|-------------|------------|
|/&lt;env&gt;/efs/&lt;sg-name&gt;/security_group/arn|/dev/efs/D01-sapmnt/security_group/arn|ARN of the created security groups
|/&lt;env&gt;/efs/&lt;sg-name&gt;/security_group/id|/dev/efs/D01-sapmnt/security_group/id|ID of the created security groups
|/&lt;env&gt;/efs/sap/list|/dev/efs/sap/list|This parameter has a list of ARN(s) for the EFS created through this configuration. The parameter is referenced during the definition of the IAM policies that authorize the use of the CMKs  |
