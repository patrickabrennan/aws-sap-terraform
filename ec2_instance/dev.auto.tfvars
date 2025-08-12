subnet_name_wildcard   = "sap_vpc_*b"     # or "*private*" — must match your subnet Name tags
subnet_selection_mode  = "first"        # if more than one match, auto-pick the first

# VIP ENI subnet selection
vip_subnet_name_wildcard   = "sap_vpc_*b"
vip_subnet_selection_mode  = "first"


default_availability_zone = "us-east-1a"
ha_azs                     = ["us-east-1a", "us-east-1b"]
enable_vip_eni = true
instances_to_create = {
    sapd01db1 = {
        availability_zone   = "us-east-1a"
        #"private_ip"       = "10.0.16.144"
        "domain"            = "pabrennan.com"        
        "application_code"  = "hana"
        "application_SID"   = "D01"
        "ha"                = true
        "ami_ID"            = "ami-0de716d6197524dd9"  #ami-01ee0f5d6dfe22e54"
        #"subnet_ID"        = "subnet-01c398cc6657832c1" 
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
        availability_zone  = "us-east-1b"
        #"private_ip"      = "10.0.0.145"
        "domain"           = "pabrennan.com"        
        "application_code" = "nw"
        "application_SID"  = "D01"
        "ha"               = true 
        "ami_ID"           = "ami-0de716d6197524dd9"   #"ami-01ee0f5d6dfe22e54"
        #"subnet_ID"       = "subnet-02057fe2ecbbe5eeb"
        "key_name"         = "sap"
        "monitoring"       = false        
        "root_ebs_size"    = 50
        "ec2_tags"         = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"    = "r5.4xlarge"
    }
}
