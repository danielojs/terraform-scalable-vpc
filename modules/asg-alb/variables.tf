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

variable "bastion_vpc_cidr" {
  description = "Bastion VPC CIDR permitted to SSH to application instances through the Transit Gateway"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name used for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application instances"
  type        = string
  default     = "t3.micro"
}
