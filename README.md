# Terraform SAP on AWS

Welcome! Here you will find the required Terraform resources required to deploy a base SAP environment using HCP Terraform. This is comprised of six() workspaces: Networtk, KMS keys, EFS, Security Groups, IAM and EC2 Instances.


## Getting started

1. Fork this repository [aws-sap-terraform](https://github.com/patrickabrennan/aws-sap-terraform) into your own account. [How to fork?](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo)
2. While you are welcome to navigate through the folders in the specific order: netwrok, kms, efs, securitygroups, iam, ec2_instance and **fill in the files named "sap.auto.tfvars" in each folder** according to what your environment requires the only things you should have to define is a variable set for a the HCP Project you will be putting the 6 workspaces in - I recommend a name of sap. The variavbles to use in the variable set are:
   
     a. aws_region = AWS Region you want to use for example us-east-1   
     b. environment = Envronment name for example dev   
     c. sap_discovery_tag = sap_relevant   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   ### Must be set to sap_relevant ### 
    
NOTE: The AMI image unless pulled from the AWS MarketPlace needs to be specified in the the [ec2_instance sap.auto.tfvars file](https://github.com/patrickabrennan/aws-sap-terraform/ec2_instance/sap.auto.tfvars) to ensure that a valid AMI for each AWS region in the U.S is listed. The Terrafrom code will select the proper one based on the region.

3. At each of the folder take a look and update as required at the ```locals.tf``` file (example [kms/locals.tf](https://github.com/patrickabrennan/aws-sap-terraform/blob/main/kms/locals.tf)). These files contain all the tags to be attached to the resources of that configuration. Update them as required.
4. Continue to section below "How to deploy"

## How to deploy

A script called 'tfc-orchestrate' may be found in this repo. This script requires a user or team token and a variable setting of ‘TFC_TOKEN’. It also requires a ‘TFC_ORG’ variable setting with the name of your TFC Orgization.

apply command is: 

./tfc-orchestrate.sh apply

Destroy command is:

./tfc-orchestrate.sh destroy

With the destroy command one needs to confirm when prompted with ‘destroy’.

The script will install as outlined below:

### Creation sequence

| Sequence | Stage | Jobs | Configuration
|------|-------|-----|-----

|1|network|kms_plan, kms_apply| [Network](network/README.md)
|2|kms|kms_plan, kms_apply| [KMS](kms/README.md)
|3|efs|efs_plan, efsS_apply| [EFS](efs/README.md)
|4|securitygroups|security_groups_plan, security_groups_apply| [Security Groups](security_group/README.md)
|5|iam|iam_plan, iam_apply| [IAM roles and policies](iam/README.md)
|6|ec2_instance|instances_plan, instances_apply| [EC2 Instances](ec2_instance/README.md)

## HCP Workplace structure 

There's one workjspoace for each type of AWS core resource created by this solution (Network, Amazon EC2 instances, Security Groups, Amazon Elastic File Systems, AWS KMS encryption keys, and AWS IAM permission policies and roles). 
SAP Landscapes often involve a large number of servers.  

Configuration of resources and the corresponding resource modules are all included in this single repository. Certain customers require this structure for audit and compliance purposes. The solution can be changed to have the resource configuration and modules separated into two different repositories. 

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
