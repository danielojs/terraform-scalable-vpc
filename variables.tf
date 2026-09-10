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
