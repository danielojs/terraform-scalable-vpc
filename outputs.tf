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

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.asg_alb.alb_dns_name
}

output "app_url" {
  description = "Public URL of the application DNS record"
  value       = "http://${module.dns.record_fqdn}"
}
