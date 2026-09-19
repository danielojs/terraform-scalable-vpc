# Stage 2: TLS at the existing ALB, with HTTP forwarding to the dedicated host.
variable "gitea_https_allowed_cidrs" {
  description = "IPv4 CIDRs allowed to reach HTTPS; restrict to your public IP during installation"
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.gitea_https_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Each entry must be an IPv4 CIDR, such as 203.0.113.10/32."
  }
}

resource "aws_acm_certificate" "gitea" {
  domain_name       = var.app_record_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-gitea" }
}

resource "aws_route53_record" "gitea_certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.gitea.domain_validation_options : option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  }

  zone_id = module.dns.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "gitea" {
  certificate_arn         = aws_acm_certificate.gitea.arn
  validation_record_fqdns = [for record in aws_route53_record.gitea_certificate_validation : record.fqdn]
}

resource "aws_vpc_security_group_ingress_rule" "gitea_https" {
  for_each = var.gitea_https_allowed_cidrs

  security_group_id = module.asg_alb.alb_security_group_id
  description       = "Gitea HTTPS access"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_lb_target_group" "gitea" {
  name        = "${var.project_name}-gitea-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpcs["app"].vpc_id

  # Check Gitea's application health after the installation has completed.
  health_check {
    path                = "/api/healthz"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Name = "${var.project_name}-gitea-tg" }
}

resource "aws_lb_target_group_attachment" "gitea" {
  target_group_arn = aws_lb_target_group.gitea.arn
  target_id        = aws_instance.gitea.id
  port             = 3000
}

resource "aws_lb_listener" "gitea_https" {
  load_balancer_arn = module.asg_alb.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = aws_acm_certificate_validation.gitea.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitea.arn
  }
}

# Redirect this application's domain while retaining the demo default action.
# Keeping the old target group in use preserves ASG health checks until retirement.
resource "aws_lb_listener_rule" "gitea_http_redirect" {
  listener_arn = module.asg_alb.http_listener_arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = var.app_record_name
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.app_record_name]
    }
  }

  depends_on = [aws_lb_listener.gitea_https]
}

output "gitea_target_group_arn" {
  description = "Target group for checking the dedicated Gitea instance health"
  value       = aws_lb_target_group.gitea.arn
}
