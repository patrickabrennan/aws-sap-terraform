environment       = "dev"
aws_region        = "us-east-1"
sap_discovery_tag = "sap_relevant"
vpc_id            = "vpc-0070f81843ca12d0a"

app_sg_list = {
  app1 = {
    description  = "App SG"
    efs_to_allow = ["dev_D01-sapmnt"]
    #efs_to_allow = ["dev_D01-sapmnt", "dev_D01-trans", "dev_D02-sapmnt", "dev_D02-trans"]
    rules = {
      "app1" = {
        source      = "vpc"
        ports       = [4237]
        description = "Allow port 4237 from all VPC"
      }
      "app2" = {
        source      = "vpc"
        ports       = [8443]
        description = "Allow port 8443 from all VPC"
      }
      "app3" = {
        source      = "vpc"
        ports       = [8080]
        description = "Allow port 8080 from all VPC"
      }
      "app4" = {
        source      = "vpc"
        ports       = [22]
        description = "Allow port 22 from all VPC"
      }
      "app5" = {
        source      = "vpc"
        ports       = [3600, 3699]
        description = "Allow port 3600-3699 from all VPC"
      }
      "app6" = {
        source      = "vpc"
        ports       = [3200, 3399]
        description = "Allow port 3200-3399 from all VPC"
      }
      "app7" = {
        source      = "self"
        protocol    = "all"
        ports       = [0, 0]
        description = "Allow all traffic from itself"
      }
      "app8" = {
        source      = "self"
        ports       = [1, 65535]
        description = "Allow all ports from itself"
      }
    }
  }
}

db_sg_list = {
  db1 = {
    description  = "DB SG"
    efs_to_allow = ["dev_D01-sapmnt"]
    #efs_to_allow = ["dev_D01-sapmnt", "dev_D01-trans", "dev_D02-sapmnt", "dev_D02-trans"]
    rules = {
      "db1" = {
        source      = "app1"
        ports       = [1, 65535]
        description = "Allow port 1-65535 from the app1 SG"
      }
      "db2" = {
        source      = "app1"
        ports       = [111]
        description = "Allow port 111 from the app1 SG"
      }
      "db3" = {
        source      = "app1"
        ports       = [2049]
        description = "Allow port 2049 from the app1 SG"
      }
      "db4" = {
        source      = "app1"
        ports       = [4000, 4002]
        description = "Allow port 4000-4002 from the app1 SG"
      }
      "db5" = {
        source      = "vpc"
        ports       = [1128, 1129]
        description = "Allow port 1128-1129 from all VPC"
      }
      "db6" = {
        source      = "vpc"
        ports       = [22]
        description = "Allow port 22 from all VPC"
      }
      "db7" = {
        source      = "vpc"
        ports       = [30013, 39913]
        description = "Allow port 30013-39913 from all VPC"
      }
      "db8" = {
        source      = "vpc"
        ports       = [30015, 39915]
        description = "Allow port 30015-39915 from all VPC"
      }
      "db9" = {
        source      = "vpc"
        ports       = [30017, 39917]
        description = "Allow port 30017-39917 from all VPC"
      }
      "db10" = {
        source      = "vpc"
        ports       = [30041, 39941]
        description = "Allow port 30041-39941 from all VPC"
      }
      "db11" = {
        source      = "vpc"
        ports       = [30044, 39944]
        description = "Allow port 30044-39944 from all VPC"
      }
      "db12" = {
        source      = "vpc"
        ports       = [4237]
        description = "Allow port 4237 from all VPC"
      }
      "db13" = {
        source      = "vpc"
        ports       = [4300, 4399]
        description = "Allow port 4300-4399 from all VPC"
      }
      "db14" = {
        source      = "vpc"
        ports       = [50013, 59914]
        description = "Allow port 50013-59914 from all VPC"
      }
      "db15" = {
        source      = "vpc"
        ports       = [8000, 8099]
        description = "Allow port 8000-8099 from all VPC"
      }
      "db16" = {
        source      = "vpc"
        ports       = [8443]
        description = "Allow port 8443 from all VPC"
      }
    }
  }
}
