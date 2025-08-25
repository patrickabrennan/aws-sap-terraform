# Use tag-based narrowing instead of Name wildcard
subnet_tag_key        = "sap_relevant"
subnet_tag_value      = "true"
subnet_selection_mode = "unique"     #"first"   # keep 'first' to auto-pick if >1 still match

vip_subnet_tag_key        = "sap_relevant"
vip_subnet_tag_value      = "true"
vip_subnet_selection_mode = "unique"       # "first"

vpc_name = "sap_vpc"

enable_vip_eni = true
instances_to_create = {
    sapd01db1 = {
        "domain"            = "pabrennan.com"        
        "application_code"  = "hana"
        "application_SID"   = "D01"
        "ha"                = true
        "ami_ID"            = "ami-01102c5e8ab69fb75" #"ami-0de716d6197524dd9"  #ami-01ee0f5d6dfe22e54"
        "key_name"          = "sap"
        "monitoring"        = false
        "root_ebs_size"     = 80 
        "ec2_tags"          = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"     = "r5.4xlarge" #"x2iedn.xlarge"
        "hana_data_storage_type"   = "gp3" 
        "hana_logs_storage_type"   = "gp3" 
        "hana_backup_storage_type" = "st1" 
        "hana_shared_storage_type" = "gp3"
    }

    sapd01cs = {
        "domain"           = "pabrennan.com"        
        "application_code" = "nw"
        "application_SID"  = "D01"
        "ha"               = true
        "ami_ID"           = "ami-01102c5e8ab69fb75" #  "ami-0de716d6197524dd9"   #"ami-01ee0f5d6dfe22e54"
        "key_name"         = "sap"
        "monitoring"       = false        
        "root_ebs_size"    = 50
        "ec2_tags"         = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"    = "r5.4xlarge"
    }

sapd02db1 = {
    "domain"           = "pabrennan.com"
    "application_code" = "hana"
    "application_SID"  = "D02"
    "ha"               = true
    "ami_ID"           = "ami-01102c5e8ab69fb75" #"ami-0de716d6197524dd9"
    "key_name"         = "sap"
    "monitoring"       = false
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
