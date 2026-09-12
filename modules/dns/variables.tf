variable "hosted_zone_name" {
  description = "Name of the existing public Route 53 hosted zone, for example example.com"
  type        = string
}

variable "record_name" {
  description = "DNS record name to point at the ALB, for example app.example.com"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  type        = string
}
