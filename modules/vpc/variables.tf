variable "name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "nat_subnet_key" {
  type    = string
  default = null
}

variable "public" {
  type    = bool
  default = false
}
