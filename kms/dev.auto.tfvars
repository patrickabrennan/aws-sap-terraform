environment = "dev"
aws_region  = "us-east-1"

keys_to_create = {
  ebs = {
    alias_name = "kms-alias-ebs"
  }
  efs        = {}
  cloudwatch = {}
  s3         = {}
}
