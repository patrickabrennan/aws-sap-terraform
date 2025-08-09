output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.sap_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "public_subnet_azs" {
  description = "AZs for the two public subnets"
  value       = [for s in aws_subnet.public : s.availability_zone]
}
