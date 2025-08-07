environment = "dev"
aws_region  = "us-east-1"

instances_to_create = {
  sapd01db1 = {
    "domain"           = "pabrennan.com"
    "application_code" = "hana"
    "application_SID"  = "D01"
    "ha"               = true
    "ami_ID"           = "ami-01ee0f5d6dfe22e54"
    "subnet_ID"        = "subnet-xxxxxxxxxxxxxxx"
    "key_name"         = "kms-alias-ebs"
    "monitoring"       = false
    "root_ebs_size"    = 80
    "ec2_tags"         = {}
    "instance_type"            = "x2iedn.xlarge"
    "hana_data_storage_type"   = "gp3"
    "hana_logs_storage_type"   = "gp3"
    "hana_backup_storage_type" = "st1"
    "hana_shared_storage_type" = "gp3"
  }

  sapd01cs = {
    "domain"           = "pabrennan.com"
    "application_code" = "nw"
    "application_SID"  = "D01"
    "ha"               = false
    "ami_ID"           = "ami-00000000000000000"
    "subnet_ID"        = "subnet-00000000000000000"
    "key_name"         = "key-name"
    "monitoring"       = true
    "root_ebs_size"    = 50
    "ec2_tags" = {
      "tag_key_1" = "tag_value_1"
    }
    "instance_type" = "c5.2xlarge"
  }
}
