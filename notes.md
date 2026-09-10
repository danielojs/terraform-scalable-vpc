Project Reference Link:
https://github.com/NotHarshhaa/DevOps-Projects/tree/master/DevOps-Project-02

Bastion VPC:  192.168.0.0/16
  Public Subnet:      192.168.1.0/24   (bastion)

App VPC:      172.20.0.0/16
  Public Subnet 1a:   172.20.1.0/24    (ALB)
  Public Subnet 1b:   172.20.2.0/24    (ALB)
  Private Subnet 1a:  172.20.11.0/24   (app / ASG)
  Private Subnet 1b:  172.20.12.0/24   (app / ASG)
