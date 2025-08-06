terraform {
  cloud {
    organization = "patrick-brennan-demo-org"
    workspaces {
      name = "sap-dev-instances"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
