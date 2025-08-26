# Network

Configuration of Network resources to be created for SAP on AWS workloads. 

Resource types created with this configuration:

#* [VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
#* [Subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
#* [Internet Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)
#* [Route Table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)

## Usage

Specify the list of CIDR's for the VPC and 2 public aubnets that will be created per the corresponding sap.auto.tfvars file following the example below. Check the detailed description for each variable in the section below.

## Dynamic configurations

* Key policies: There are two types of key policies to be applied to each of your keys. One of them is specific to EBS, granting required extra permissions for when the key is used with the Autoscaling service. The other is common, used for all the other scenarios, and doesn't require the extra permissions.

## Examples

```hcl
aws_region = var.aws_region
environment = var.environment
vpc_cidr    = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]

# Optionally add your own extra tags here
extra_tags = {
  owner = "sap-team"
}
```

## Regarding the input variables below, this repo defines environment, aws_region, and sap_discovery_tag in the project variable set as they are needed in other workspaces. The CIDR for the VPC and subnets are in the sap.auto.tfvars file.

## Input variables

| Name | Description | Example | Required |
|------|-------------|--------|--------|
|vpc_cidr|VPC CIDR|"10.10.0.0/16"|Yes
|public_subnet_cidr|list of public subnet CIDR to use|["10.10.1.0/24", "10.10.2.0/24"]|Yes

