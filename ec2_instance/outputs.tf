output "azs_with_subnets"  { value = local.azs_with_subnets }
output "subnet_id_by_az"   { value = local.subnet_id_by_az }
#output "az_assignment"     { value = { for k, v in local.all_instances : k => v.availability_zone } }
