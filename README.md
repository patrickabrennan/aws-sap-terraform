# Terraform SAP on AWS

Welcome! Here you will find the required Terraform resources required to deploy a base SAP environment, comprised of KMS keys, EFS, Security Groups, IAM and EC2 Instances.

//Find the full guidance on how to use this code on [the official blog post](https://aws.amazon.com/blogs/awsforsap/terraform-your-sap-infrastructure-on-aws-2/)

## Getting started

1. Fork this repository [aws-sap-terraform](https://github.com/patrickabrennan/aws-sap-terraform) into your own account. [How to fork?](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo)
2. Navigate through the folders in the specific order: netwrok, kms, efs, securitygroups, iam, ec2_instance and **fill in the files named "sap.tfvars" in each folder** according to what your environment requires. More information on how to fill in these files can be found on each specific resource page under Configurations in the left menu. 
3. At each of the folder take a look and update as required at the ```locals.tf``` file (example [kms/locals.tf](https://github.com/patrickabrennan/aws-sap-terraform/blob/main/kms/locals.tf)). These files contain all the tags to be attached to the resources of that configuration. Update them as required.
4. Push your updated code to your repository.
5. Add tag key "sap_relevant" and value "true" to the VPC you're using for this deployment.
![VPC tag](images/vpc-tag.png)
6. Continue to section below "How to deploy"

## How to deploy

A script called tfc-orchestrate may be found in this repo. You need to set two variables: HCP_TOKEN and HCP_ORG


Now follow the order below to deploy your resources on the AWS account.

### Creation sequence

| Sequence | Stage | Jobs | Configuration
|------|-------|-----|-----

|1|network
|2|kms|kms_plan, kms_apply| [KMS](kms/README.md)
|3|efs|efs_plan, efsS_apply| [EFS](efs/README.md)
|4|securitygroups|security_groups_plan, security_groups_apply| [Security Groups](security_group/README.md)
|5|iam|iam_plan, iam_apply| [IAM roles and policies](iam/README.md)
|6|ec2_instance|instances_plan, instances_apply| [EC2 Instances](ec2_instance/README.md)

## Folder structure 

There's one folder for each type of AWS core resource created by this solution (Network, Amazon EC2 instances, Security Groups, Amazon Elastic File Systems, AWS KMS encryption keys, and AWS IAM permission policies and roles). 
SAP Landscapes often involve a large number of servers.  

Configuration of resources and the corresponding resource modules are all included in this single repository. Certain customers require this structure for audit and compliance purposes. The solution can be changed to have the resource configuration and modules separated into two different repositories. 

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
