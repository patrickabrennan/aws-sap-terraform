aws_region = "us-east-1"
environment = "dev"
vpc_cidr    = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]

# Optionally add your own extra tags here
extra_tags = {
  owner = "sap-team"
}
