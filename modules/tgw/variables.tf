variable "name_prefix" {
  description = "Prefix used to name TGW resources"
  type        = string
}


# Bastion VPC variables
variable "bastion_vpc_id" {
  description = "ID of the bastion VPC"
  type        = string
}

variable "bastion_vpc_cidr" {
  description = "CIDR block of the bastion VPC"
  type        = string
}

variable "bastion_attachment_subnet_ids" {
  description = "Subnet IDs used for the bastion VPC Transit Gateway attachment"
  type        = list(string)
}

variable "bastion_route_table_id" {
  description = "Route table ID in the bastion VPC that needs a route to the app VPC"
  type        = string
}


# App VPC variables
variable "app_vpc_id" {
  description = "ID of the app VPC"
  type        = string
}

variable "app_vpc_cidr" {
  description = "CIDR block of the app VPC"
  type        = string
}

variable "app_attachment_subnet_ids" {
  description = "Subnet IDs used for the app VPC Transit Gateway attachment"
  type        = list(string)
}

variable "app_public_route_table_id" {
  description = "App VPC public route table ID"
  type        = string
}

variable "app_private_route_table_id" {
  description = "App VPC private route table ID"
  type        = string
}
