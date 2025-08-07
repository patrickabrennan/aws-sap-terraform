environment = "dev"
aws_region = "us-east-1"

instances_to_create = {
    sapd01db1 = {
        "private_ip"        = "10.0.16.144"
        "domain"            = "pabrennan.com"        
        "application_code"  = "hana"
        "application_SID"   = "D01"
        "ha"                = false     
        "ami_ID"            = "ami-01ee0f5d6dfe22e54"
        "subnet_ID"         = "subnet-01c398cc6657832c1"
        "key_name"          = "testing"
        "monitoring"        = false
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
        "private_ip"       = "10.0.0.145"
        "domain"           = "pabrennan.com"        
        "application_code" = "nw"
        "application_SID"  = "D01"
        "ha"               = false            
        "ami_ID"           = "ami-01ee0f5d6dfe22e54"
        "subnet_ID"        = "subnet-02057fe2ecbbe5eeb"
        "key_name"         = "testing"
        "monitoring"        = false        
        "root_ebs_size"    = 50
        "ec2_tags"         = { 
            "tag_key_1" = "tag_value_1" 
        }
        "instance_type"    = "c5.2xlarge"
    }
}
