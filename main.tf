# Root module: application VPC, application compute/load balancer, and DNS.
# Administrative access uses Systems Manager through the application NAT gateway.

module "vpcs" {
  source = "./modules/vpc"

  for_each = {
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

}

module "dns" {
  source = "./modules/dns"

  hosted_zone_name = var.hosted_zone_name
  record_name      = var.app_record_name
  alb_dns_name     = module.asg_alb.alb_dns_name
  alb_zone_id      = module.asg_alb.alb_zone_id
}
