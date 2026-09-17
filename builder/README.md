# BookStack AMI builder

Independent Terraform root for a standalone Ubuntu 24.04 instance in Singapore.
State uses `s3://kami-dev-tfstate/builder/terraform.tfstate`; the parent stack is separate.
Run Terraform from this directory, not the repository root.
Set `bookstack_http_cidr` to your browser's public IPv4 address followed by `/32`
when prompted by `terraform plan`, or save it in a local `terraform.tfvars` file.

```sh
terraform init
terraform plan -out=builder.tfplan
terraform apply builder.tfplan
terraform output
```

The stack uses the existing `ec2-ssm-role` (AmazonSSMManagedInstanceCore),
`universal-key` key pair, and state bucket. It creates a dedicated VPC, public
subnet, internet gateway, routing, security group, instance profile, and EC2 instance.
There is no Auto Scaling group or load balancer attachment.

Connect through EC2 > Instances > project02-bookstack-builder > Connect >
Session Manager, or use the `connect_command` output (requires the local Session
Manager plugin). Inbound HTTP (TCP port 80) is allowed from `bookstack_http_cidr`
for testing BookStack in your browser. The public IPv4 address also provides
outbound package repository and Systems Manager connectivity.

The builder has 2 GiB RAM, 20 GiB encrypted gp3 storage, IMDSv2, standard CPU
credits, and API termination protection. Its root volume survives termination.
This retention is not a backup: create an AMI and back up application data later.
BookStack is not installed by this stack.

EC2, EBS and public IPv4 charges apply. Stop the instance when unused; storage
charges continue. Its public IP can change after stopping and starting.
For intentional cleanup, first preserve required data, disable termination
protection, then destroy this stack. The retained root disk requires separate
cleanup and continues to incur storage charges until deleted.
