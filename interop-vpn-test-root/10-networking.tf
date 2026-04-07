
resource "aws_vpc" "main" {
  count = var.create_networking_resources ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = format("%s-%s-vpc", var.app_name, var.env) }
}

resource "aws_subnet" "main" {
  count = var.create_networking_resources ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = format("%s-%s-subnet", var.app_name, var.env) }
}

resource "aws_internet_gateway" "main" {
  count = var.create_networking_resources ? 1 : 0

  vpc_id = aws_vpc.main[0].id
  tags   = { Name = format("%s-%s-igw", var.app_name, var.env) }
}

resource "aws_route_table" "main" {
  count = var.create_networking_resources ? 1 : 0

  vpc_id = aws_vpc.main[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  tags = { Name = format("%s-%s-rt", var.app_name, var.env) }
}

resource "aws_route_table_association" "main" {
  count = var.create_networking_resources ? 1 : 0

  subnet_id      = aws_subnet.main[0].id
  route_table_id = aws_route_table.main[0].id
}
