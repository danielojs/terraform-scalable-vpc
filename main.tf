# Root module: wires together all child modules for Project 02.
#
# Build/apply order (dependency chain, top to bottom):
#   1. vpc      - both VPCs, subnets, IGWs, NAT, route tables (no dependencies)
#   2. tgw      - Transit Gateway + attachments (depends on: vpc, for VPC/subnet IDs)
#   3. bastion  - EC2 bastion host (depends on: vpc, for subnet + SG placement)
#   4. asg-alb  - Launch Template, ASG, Target Group, ALB (depends on: vpc, tgw for routing)
#   5. dns      - Route 53 record aliasing to ALB (depends on: asg-alb, for ALB DNS name)

module "vpcs" {
  source = "./modules/vpc"

  for_each = {
    # VPC 1
    bastion = {
      cidr_block = "192.168.0.0/16"
      public     = true

      public_subnets = {
        public_1 = {
          cidr = "192.168.1.0/24"
          az   = "ap-southeast-1a"
        }
      }

      private_subnets = {}
    }

    # VPC 2
    app = {
      cidr_block = "172.20.0.0/16"
      public     = true

      public_subnets = {
        public_1 = {
          cidr = "172.20.1.0/24"
          az   = "ap-southeast-1b"
        }

        public_2 = {
          cidr = "172.20.2.0/24"
          az   = "ap-southeast-1c"
        }
      }

      private_subnets = {
        private_1 = {
          cidr = "172.20.11.0/24"
          az   = "ap-southeast-1b"
        }

        private_2 = {
          cidr = "172.20.12.0/24"
          az   = "ap-southeast-1c"
        }
      }

      nat_subnet_key = "public_2"
    }
  }

  name            = each.key
  vpc_cidr        = each.value.cidr_block
  public          = each.value.public
  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets
  nat_subnet_key  = try(each.value.nat_subnet_key, null)
}


module "tgw" {
  source = "./modules/tgw"

  name_prefix = var.project_name


  bastion_vpc_id   = module.vpcs["bastion"].vpc_id
  bastion_vpc_cidr = module.vpcs["bastion"].vpc_cidr

  # The bastion VPC currently has just one public subnet
  bastion_attachment_subnet_ids = [
    module.vpcs["bastion"].public_subnet_ids["public_1"]
  ]

  bastion_route_table_id = module.vpcs["bastion"].public_route_table_id


  app_vpc_id   = module.vpcs["app"].vpc_id
  app_vpc_cidr = module.vpcs["app"].vpc_cidr

  # A TGW attachment needs one subnet per AZ
  app_attachment_subnet_ids = [
    module.vpcs["app"].private_subnet_ids["private_1"],
    module.vpcs["app"].private_subnet_ids["private_2"],
  ]

  app_public_route_table_id  = module.vpcs["app"].public_route_table_id
  app_private_route_table_id = module.vpcs["app"].private_route_table_id
}


module "bastion" {
  source = "./modules/bastion"

  name_prefix      = var.project_name
  key_name         = "universal-key"
  vpc_id           = module.vpcs["bastion"].vpc_id
  subnet_id        = module.vpcs["bastion"].public_subnet_ids["public_1"]
  allowed_ssh_cidr = "110.136.32.38/32"
}

module "asg_alb" {
  source = "./modules/asg-alb"

  name_prefix = var.project_name
  vpc_id      = module.vpcs["app"].vpc_id

  public_subnet_ids = [
    module.vpcs["app"].public_subnet_ids["public_1"],
    module.vpcs["app"].public_subnet_ids["public_2"],
  ]

  private_subnet_ids = [
    module.vpcs["app"].private_subnet_ids["private_1"],
    module.vpcs["app"].private_subnet_ids["private_2"],
  ]

  bastion_vpc_cidr = module.vpcs["bastion"].vpc_cidr
  key_name         = "universal-key"
}

module "dns" {
  source = "./modules/dns"

  hosted_zone_name = var.hosted_zone_name
  record_name      = var.app_record_name
  alb_dns_name     = module.asg_alb.alb_dns_name
  alb_zone_id      = module.asg_alb.alb_zone_id
}
