output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID of application instances"
  value       = aws_security_group.app.id
}

output "alb_arn" {
  description = "ARN of the shared application load balancer"
  value       = aws_lb.this.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN for application-specific routing rules"
  value       = aws_lb_listener.http.arn
}
