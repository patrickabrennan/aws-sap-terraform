environment = "dev"
aws_region  = "us-east-1"

instances_to_create = {
  sapd01db1 = {
    #"private_ip"       = "172.31.16.50"
    "domain"           = "pabrennan.com"
    "application_code" = "hana"
    "application_SID"  = "D01"
    "ha"               = true
    "ami_ID"           = "ami-01ee0f5d6dfe22e54"
    #"subnet_ID"        = "subnet-00000000000000000"
    "key_name"         = "kms-alias-ebs"
    "monitoring"       = false #true
    "root_ebs_size"    = 80
    #"ec2_tags" = {
      #"tag_key_1" = "tag_value_1"
    #}
    "instance_type"            = "x2iedn.xlarge"
    "hana_data_storage_type"   = "gp3"
    "hana_logs_storage_type"   = "gp3"
    "hana_backup_storage_type" = "st1"
    "hana_shared_storage_type" = "gp3"
  }

  sapd01cs = {
    #"private_ip"       = "172.31.0.50"
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

/*
  sapd02db1 = {
    "private_ip"       = "172.31.16.51"
    "domain"           = "mylab.com"
    "application_code" = "hana"
    "application_SID"  = "D02"
    "ha"               = true
    "ami_ID"           = "ami-00000000000000000"
    "subnet_ID"        = "subnet-00000000000000000"
    "key_name"         = "key-name"
    "monitoring"       = true
    "root_ebs_size"    = 80
    "ec2_tags" = {
      "tag_key_1" = "tag_value_1"
    }
    "instance_type" = "r5.8xlarge"
    "custom_ebs_config" = [
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
*/
