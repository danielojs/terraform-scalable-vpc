variable "name_prefix" {
  description = "Prefix used to name application resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the application VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Auto Scaling application instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for application instances"
  type        = string
  default     = "t3.micro"
}

variable "ssm_role_name" {
  description = "Existing EC2 role granting AmazonSSMManagedInstanceCore permissions"
  type        = string
  default     = "ec2-ssm-role"
}
