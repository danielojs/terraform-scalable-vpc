output "bastion_vpc_id" {
  description = "Bastion VPC ID"
  value       = module.vpcs["bastion"].vpc_id
}

output "app_vpc_id" {
  description = "Application VPC ID"
  value       = module.vpcs["app"].vpc_id
}

output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = module.tgw.transit_gateway_id
}
