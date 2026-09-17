terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "kami-dev-tfstate"
    key          = "builder/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "default"
  default_tags {
    tags = {
      Project   = "project02"
      Purpose   = "bookstack-ami-builder"
      ManagedBy = "Terraform"
    }
  }
}

# Pin the image so later plans do not replace the working builder automatically.
variable "ubuntu_ami_id" {
  description = "Canonical Ubuntu 24.04 amd64 AMI in Singapore, verified at creation."
  type        = string
  default     = "ami-0ba4172b23e57d5a8"
}

variable "bookstack_http_cidr" {
  description = "IPv4 CIDR allowed to access BookStack over HTTP, such as your public IP followed by /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.bookstack_http_cidr))
    error_message = "Provide a valid IPv4 CIDR, such as 203.0.113.10/32."
  }
}

resource "aws_vpc" "builder" {
  cidr_block           = "10.90.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "project02-builder-vpc" }
}

resource "aws_subnet" "builder" {
  vpc_id            = aws_vpc.builder.id
  cidr_block        = "10.90.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "project02-builder-subnet" }
}

resource "aws_internet_gateway" "builder" {
  vpc_id = aws_vpc.builder.id
  tags   = { Name = "project02-builder-igw" }
}

resource "aws_route_table" "builder" {
  vpc_id = aws_vpc.builder.id
  tags   = { Name = "project02-builder-public" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.builder.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.builder.id
}

resource "aws_route_table_association" "builder" {
  subnet_id      = aws_subnet.builder.id
  route_table_id = aws_route_table.builder.id
}

# Session Manager uses outbound connections; BookStack HTTP access is allowed below.
resource "aws_security_group" "builder" {
  name        = "project02-builder-sg"
  description = "Standalone builder accessed through AWS Session Manager"
  vpc_id      = aws_vpc.builder.id
  tags        = { Name = "project02-builder-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "bookstack_http" {
  security_group_id = aws_security_group.builder.id
  description       = "BookStack HTTP access"
  cidr_ipv4         = var.bookstack_http_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "builder" {
  security_group_id = aws_security_group.builder.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Existing role, verified to trust EC2 and grant AmazonSSMManagedInstanceCore.
data "aws_iam_role" "ssm" {
  name = "ec2-ssm-role"
}

resource "aws_iam_instance_profile" "builder" {
  name = "project02-builder-profile"
  role = data.aws_iam_role.ssm.name
}

resource "aws_instance" "builder" {
  ami                         = var.ubuntu_ami_id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.builder.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.builder.id]
  iam_instance_profile        = aws_iam_instance_profile.builder.name
  key_name                    = "universal-key"
  disable_api_termination     = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = false
    tags                  = { Name = "project02-builder-root" }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = { Name = "project02-bookstack-builder" }

  depends_on = [
    aws_route.internet,
    aws_route_table_association.builder,
    aws_vpc_security_group_egress_rule.builder,
  ]
}

output "instance_id" {
  value = aws_instance.builder.id
}

output "public_ip" {
  value = aws_instance.builder.public_ip
}

output "root_volume_id" {
  value = aws_instance.builder.root_block_device[0].volume_id
}

output "connect_command" {
  value = "aws ssm start-session --target ${aws_instance.builder.id} --region ap-southeast-1 --profile default"
}
