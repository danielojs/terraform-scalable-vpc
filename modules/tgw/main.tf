resource "aws_ec2_transit_gateway" "this" {
  description = "${var.name_prefix} transit gateway"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "${var.name_prefix}-tgw"
  }
}


# Transit Gateway Route Table (TGW-side)
resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "bastion" {
  subnet_ids         = var.bastion_attachment_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.bastion_vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app" {
  subnet_ids         = var.app_attachment_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.app_vpc_id

  tags = {
    Name = "${var.name_prefix}-app-attachment"
  }
}

resource "aws_ec2_transit_gateway_route" "to_bastion" {
  destination_cidr_block         = var.bastion_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.bastion.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route" "to_app" {
  destination_cidr_block         = var.app_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_association" "bastion" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.bastion.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_association" "app" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}


# VPC Route Table (VPC-side)
resource "aws_route" "bastion_to_vpc" {
  route_table_id         = var.bastion_route_table_id
  destination_cidr_block = var.app_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "app_public_to_bastion" {
  route_table_id         = var.app_public_route_table_id
  destination_cidr_block = var.bastion_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "app_private_to_bastion" {
  route_table_id         = var.app_private_route_table_id
  destination_cidr_block = var.bastion_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}
