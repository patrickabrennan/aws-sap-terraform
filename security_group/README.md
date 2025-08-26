# Security Groups

Configuration of KMS resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

* [Security Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html)
* [Security Group Rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)

## Usage

Specify the list of Security Groups to be created in the corresponding sap.tfvars file. One can use the field "efs_to_allow" to reference the security groups automatically created by the [EFS](../efs/README.md) module.

## Examples

The following example creates two security groups: one for the app (called app1) and one for the database (called db1). You can declare as many security groups as you need under the variables "app_sg_list" and "db_sg_list". App security groups are created before database security groups. You can reference app security groups as inbound allows to your database security groups. More details on using the fields below.

```hcl
environment = "dev"
aws_region = "us-east-1"
sap_discovery_tag = "sap_relevant"

app_sg_list = {
  app1 = {
    description  = "App SG"
    efs_to_allow = ["sapmedia", "sapmnt", "saptrans"]
    rules = {
      "app1" = {
        source = "vpc"
        ports  = [4237]
      }
      "app2" = {
        source = "vpc"
        ports  = [8443]
      }
      "app3" = {
        source   = "self"
        protocol = "all"
        ports    = [0, 0]
      }
      "app4" = {
        source = "self"
        ports  = [1, 65535]
      }
    }
  }
}

db_sg_list = {
  db1 = {
    description  = "DB SG"
    efs_to_allow = ["sapmedia", "sapmnt", "saptrans"]
    rules = {
      "db1" = {
        source = "app1"
        ports  = [1, 65535]
      }
      "db2" = {
        source = "app1"
        ports  = [111]
      }
      "db3" = {
        source = "vpc"
        ports  = [1128, 1129]
      }
      "db4" = {
        source = "vpc"
        ports  = [8443]
      }
    }
  }
}
```

### Details on the ```rules``` field:
```hcl
rules = {
    "app1" = {
        source = "vpc"       // All the IPs within the given VPC will be allowed in to port 8443
        ports  = [8443]
    }
    "app3" = {
        source   = "self"    // All the traffic across all protocols and all ports from the same Security Group will be allowed in
        protocol = "all"
        ports    = [0, 0]
    }
    "app4" = {
        source = "self"      // All the traffic from port 1 to 65535 will be allowed from the given Security Group into itself
        ports  = [1, 65535]
    }
    "db1" = {
        source = "app1"      // Traffic from port 1 to 65535 coming from Security Group app1 will be allowed in Security Group db1. Available only for security groups declared under variable "db_sg_list" in the configuration
        ports  = [1, 65535]
    }
}
```


## Regarding the input variables below, this repo defines environment and aws_region in the project variable set as they are needed in other workspaces. The app_sg_list and db_sg_list are defined in the sap.auto.tfvars file.


## Input variables
| Name | Description | Example | Required |
|------|-------------|--------|--------|
|environment|Environment name|dev|Yes
|aws_region|Region where resources are being deployed|us-east-1|Yes
|app_sg_list|Key-value map. The key (examples above are "app1", and "db1") will be used as the security group name. See below for details|See below|Yes
|db_sg_list|Key-value map. The key (examples above are "app1", and "db1") will be used as the security group name. See below for details|See below|Yes

### ```app_sg_list``` and ```db_sg_list``` variable details
| Name | Description | Example | Required |
|------|-------------|--------|--------|
|description|Description for the security group|My description|Yes
|efs_to_allow|List of EFS names to have their security groups changed to allow inbound traffic from this new security group. This HAS to match the EFS described in the EFS configuration (TODO - reference a link)|["sapmedia", "sapmnt"]|No
|rules|The rules to be created on each security group|See below for details|No

### ```rules``` variable details
| Name | Description | Example | Required |
|------|-------------|--------|--------|
|source|Where are the connections coming from to be allowed in this security group? Valid values are "self", "vpc", and "mySGName". MySGName is only allowed inside variable "db_sg_list". Check the example above "Detailing the rules field" for more details|self|Yes
|protocol|Protocol to be used for the rule. Defaults to "tcp"|tcp|No
|ports|List of ports containing two values: to and from, to be allowed|[1, 65535]|Yes

## Parameters created by this configuration

| Parameter | Example | Where-used |
|------|-------------|------------|
|/&lt;env&gt;/security_group/SG_NAME/id|/dev/security_group/app1/id|ID of the created security group
