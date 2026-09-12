output "record_fqdn" {
  description = "Fully qualified domain name of the ALB alias record"
  value       = aws_route53_record.alb.fqdn
}
