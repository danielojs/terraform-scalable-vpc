resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.public

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_eip" "nat" {
  count = var.nat_subnet_key != null ? 1 : 0

  domain = "vpc"
}

# NAT gateway needs - an EIP, a public subnet, internet gateway and route from the public subnet to the internet gateway
resource "aws_nat_gateway" "this" {
  count = var.nat_subnet_key != null ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.nat_subnet_key].id

  depends_on = [aws_internet_gateway.this]
}


# Public subnets route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[each.key].id
}


# Private subnets route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private" {
  count = var.nat_subnet_key != null ? 1 : 0 # Only create a route if a NAT subnet key is provided

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id # Only associate with the NAT gateway if a NAT subnet key is provided
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[each.key].id
}
