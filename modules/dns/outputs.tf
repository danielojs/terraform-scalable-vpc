output "record_fqdn" {
  description = "Fully qualified domain name of the ALB alias record"
  value       = aws_route53_record.alb.fqdn
}

output "hosted_zone_id" {
  description = "Public hosted zone for certificate validation records"
  value       = data.aws_route53_zone.this.zone_id
}
