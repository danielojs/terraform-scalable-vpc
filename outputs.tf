output "app_vpc_id" {
  description = "Application VPC ID"
  value       = module.vpcs["app"].vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.asg_alb.alb_dns_name
}

output "app_url" {
  description = "Public URL of the application DNS record"
  value       = "http://${module.dns.record_fqdn}"
}
