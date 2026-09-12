variable "aws_region" {
  description = "Default AWS region for this project"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Short name used as a prefix/tag for all resources in this project"
  type        = string
  default     = "project02"
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 hosted-zone name"
  type        = string
  default     = "rezedev.site"
}

variable "app_record_name" {
  description = "DNS record name for the application ALB"
  type        = string
  default     = "rezedev.site"
}
