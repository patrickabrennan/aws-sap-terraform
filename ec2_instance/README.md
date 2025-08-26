# EC2 Instances

Configuration of EC2 resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

* [EC2 instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
* [EBS Volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume)
* [Elastic Network Interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface)
* [DNS Record](https://www.terraform.io/docs/providers/aws/r/route53_record.html)

## Usage

Specify the list of EC2 instances to be created in the corresponding sap.auto.tfvars file following the example below. Check the detailed description for each variable in the section below. For SAP HANA databases, EC2 instances can be specified to be created with ***standard HANA storage configuration*** or ***custom HANA storage configuration***

## Examples

### Example 1 - creation of 2 instances (one application server, one hana database) leveraging standard storage configuration.  

You only need to specify the EC2 instance type and storage type you want to use with your HANA database. The module will dynamically identify the required EBS storage resources to be created, as per [Storage Configuration for SAP HANA](https://docs.aws.amazon.com/sap/latest/sap-hana/hana-ops-storage-config.html).

```hcl
instances_to_create = {
    sapd01db1 = {
        "domain"            = "mylab.com"        
        "application_code"  = "hana"
        "application_SID"   = "D01"
        "ha"                = false     
        "key_name"          = "mycmk"
        "monitoring"        = true
        "root_ebs_size"     = 80 
        "ec2_tags"          = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"     = "x2iedn.xlarge"
        "hana_data_storage_type"   = "gp3" 
        "hana_logs_storage_type"   = "gp3" 
        "hana_backup_storage_type" = "st1" 
        "hana_shared_storage_type" = "gp3"
    }

    sapd01cs = {
        "domain"           = "mylab.com"        
        "application_code" = "nw"
        "application_SID"  = "D01"
        "ha"               = false            
        "key_name"         = "mycmk"
        "monitoring"        = true        
        "root_ebs_size"    = 50
        "ec2_tags"         = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"    = "c5.2xlarge"
    }
}
```

### Example 2 - creation of 1 instance (database server) leveraging a custom storage configuration

You specify the EC2 instance type and a detailed custom EBS configuration for your HANA database. The ec2module will create the EBS resources as per your specification.

```hcl
instances_to_create = {
    sapd02db1 = {
        "domain"            = "mylab.com"        
        "application_code"  = "hana"
        "application_SID"   = "D02"
        "ha"                = true     
        "key_name"          = "mycmk"
        "monitoring"        = true
        "root_ebs_size"     = 80 
        "ec2_tags"          = { 
            "tag_key_1" = "tag_value_1" 
        }        
        "instance_type"     = "r5.8xlarge"
        "custom_ebs_config" =  [
            {
                identifier = "data",
                disk_nb    = 3,
                disk_size  = 225,
                disk_type  = "gp2"
            },
            {
                identifier = "log",
                disk_nb    = 2,
                disk_size  = 300,
                iops       = 3000,
                throughput = 250,
                disk_type  = "gp3"
            },
            {
                identifier = "backup",
                disk_nb    = 1,
                disk_size  = 512,
                iops       = 4500,
                throughput = 750,                
                disk_type  = "gp3"
            },
            {
                identifier = "shared",
                disk_nb    = 1,
                disk_size  = 512,
                disk_type  = "gp2"
            },
            {
                identifier = "tmp",
                disk_nb    = 1,
                disk_size  = 30,
                iops       = 3000,
                throughput = 125,                
                disk_type  = "gp3"
            },
            {
                identifier = "usrsap",
                disk_nb    = 1,
                disk_size  = 60,
                iops       = 3000,
                throughput = 125,                
                disk_type  = "gp3"
            },
            {
                identifier = "swap",
                disk_nb    = 1,
                disk_size  = 20,
                iops       = 3000,
                throughput = 125,                
                disk_type  = "gp3"
            }
        ]                
    }
}
```


## Regarding the input variables below, this repo defines environment and aws_region in the project variable set as they are needed in other workspaces. The following are not required as they are determined automatically:
```hcl
## - public IP
## - subnet_id
```
## When ha = true the primary nodes are put in one subnet and all the secondaries are put in anther subnet. The subnet ID's are determined automatcially.

## The following inputs are defind in the sap.auto.tfvars file. 


## Input variables

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|ami_id_map|list of 4 valid ami_id, one for for each AWS U.S. Region |us-east-1 = "ami-086ecd7a7c7733550"|Yes
|domain|Domain EC2 instance needs to be configured with |mycorp.com|Yes
|application_code|Identifies the type of EC2 instance (use "hana" for SAP HANA, use "nw" for SAP NetWeaver Application Servers.|hana|Yes
|application_SID|SAP system SID |D01|Yes
|ha|Determines if instance will be part of a High Availability cluster. If it's true, will create the instance with an IAM role with broader permissions, required for HA. If it's false, the permissions given are narrower |true|Yes
|key_name|Name of KMS CMK alias for EBS encryption |mycmk|Yes
|monitoring|If set to true, enables detailed monitoring |false|Yes
|root_ebs_size|Size of root EBS volume (in GiBs) |80|Yes
|ec2_tags|Key value map with EC2 tags common to all SAP instances | { "app"= "SAP", "cost_center"= "12345" } |No
|instance_type|EC2 instance type to be created|x2iedn.4xlarge|Yes
|hana_data_storage_type|EBS storage type to be used for HANA data volumes|gp3|Yes
|hana_logs_storage_type|EBS storage type to be used for HANA log volumes|gp3|Yes
|hana_backup_storage_type|EBS storage type to be used for HANA backup volume|st1|Yes
|hana_shared_storage_type|EBS storage type to be used for HANA shared volumes|gp3|Yes



## Parameters in AWS Systems Manager Parameter Store updated by this configuration

N/A
