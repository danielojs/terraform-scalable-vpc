# Stage 1: create a dedicated Gitea host without changing existing ALB routing.
# Docker installation, data-disk mounting, and Compose deployment follow separately.

variable "gitea_instance_type" {
  description = "Instance size for the single-node Gitea learning deployment"
  type        = string
  default     = "t3.micro"
}

variable "gitea_data_size_gib" {
  description = "Size of the separate Gitea data disk; EBS volumes cannot be shrunk"
  type        = number
  default     = 20

  validation {
    condition     = var.gitea_data_size_gib >= 20 && floor(var.gitea_data_size_gib) == var.gitea_data_size_gib
    error_message = "Choose a whole number of GiB, at least 20."
  }
}

data "aws_subnet" "gitea" {
  id = module.vpcs["app"].private_subnet_ids["private_1"]
}

data "aws_ami" "gitea_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Reuse the same existing SSM role as the application module, in a separate profile.
data "aws_iam_role" "gitea_ssm" {
  name = "ec2-ssm-role"
}

resource "aws_iam_instance_profile" "gitea" {
  name = "${var.project_name}-gitea-ssm"
  role = data.aws_iam_role.gitea_ssm.name
}

resource "aws_security_group" "gitea" {
  name        = "${var.project_name}-gitea-sg"
  description = "Gitea web access from ALB; administrative access through SSM"
  vpc_id      = module.vpcs["app"].vpc_id

  tags = { Name = "${var.project_name}-gitea-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "gitea_from_alb" {
  security_group_id            = aws_security_group.gitea.id
  referenced_security_group_id = module.asg_alb.alb_security_group_id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "gitea_outbound" {
  security_group_id = aws_security_group.gitea.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Prepare the ALB-to-Gitea path while retaining its existing port-80 demo path.
resource "aws_vpc_security_group_egress_rule" "alb_to_gitea" {
  security_group_id            = module.asg_alb.alb_security_group_id
  referenced_security_group_id = aws_security_group.gitea.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}

resource "aws_instance" "gitea" {
  ami                         = data.aws_ami.gitea_ubuntu.id
  instance_type               = var.gitea_instance_type
  subnet_id                   = data.aws_subnet.gitea.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.gitea.id]
  iam_instance_profile        = aws_iam_instance_profile.gitea.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 16
    encrypted             = true
    delete_on_termination = true
  }

  lifecycle {
    # A new Ubuntu image must not silently replace this manually configured host.
    # OS updates are maintained in place; an AMI migration is a deliberate task.
    ignore_changes  = [ami]
    prevent_destroy = false
  }

  tags = { Name = "${var.project_name}-gitea" }
}

# A separate Terraform resource keeps the data disk independent of the OS disk.
resource "aws_ebs_volume" "gitea_data" {
  availability_zone = data.aws_subnet.gitea.availability_zone
  size              = var.gitea_data_size_gib
  type              = "gp3"
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }

  tags = { Name = "${var.project_name}-gitea-data" }
}

resource "aws_volume_attachment" "gitea_data" {
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.gitea_data.id
  instance_id                    = aws_instance.gitea.id
  stop_instance_before_detaching = true
}

output "gitea_instance_id" {
  description = "Dedicated Gitea instance to connect to using Session Manager"
  value       = aws_instance.gitea.id
}

output "gitea_private_ip" {
  value = aws_instance.gitea.private_ip
}

output "gitea_data_volume_id" {
  description = "Blank data disk; identify by volume ID before formatting and mounting"
  value       = aws_ebs_volume.gitea_data.id
}
