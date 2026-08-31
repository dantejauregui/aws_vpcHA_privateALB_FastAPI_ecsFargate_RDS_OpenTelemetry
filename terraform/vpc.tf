resource "aws_vpc" "fastApi_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# This Data block will call the availability_zones that exist in the Default Region set in the Provider configuration: 
data "aws_availability_zones" "available" {
  state = "available"
}

# Creating subnets using "for_each":
locals {
  subnets = {
    fastApi_sn_public_1 = {
      cidr = "10.0.1.0/24"
      az   = data.aws_availability_zones.available.names[0]
    }

    fastApi_sn_public_2 = {
      cidr = "10.0.2.0/24"
      az   = data.aws_availability_zones.available.names[1]
    }

    fastApi_sn_private_1 = {
      cidr = "10.0.11.0/24"
      az   = data.aws_availability_zones.available.names[0]
    }

    fastApi_sn_private_2 = {
      cidr = "10.0.12.0/24"
      az   = data.aws_availability_zones.available.names[1]
    }
  }
}
resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id            = aws_vpc.fastApi_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

}


resource "aws_internet_gateway" "fastApi_igw" {
  vpc_id = aws_vpc.fastApi_vpc.id
}

resource "aws_eip" "fastApi_ip_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.fastApi_igw]
}
resource "aws_eip" "fastApi_ip_2" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.fastApi_igw]
}
resource "aws_nat_gateway" "fastApi_ng_1" {
  allocation_id = aws_eip.fastApi_ip_1.id
  subnet_id     = aws_subnet.this["fastApi_sn_public_1"].id

  # it is recommended to add an explicit dependency on the Internet Gateway:
  depends_on = [aws_internet_gateway.fastApi_igw]
}
resource "aws_nat_gateway" "fastApi_ng_2" {
  allocation_id = aws_eip.fastApi_ip_2.id
  subnet_id     = aws_subnet.this["fastApi_sn_public_2"].id

  # it is recommended to add an explicit dependency on the Internet Gateway:
  depends_on = [aws_internet_gateway.fastApi_igw]
}


resource "aws_route_table" "fastApi_public_rt" {
  vpc_id = aws_vpc.fastApi_vpc.id

  # Send all internet traffic (0.0.0.0/0) to the Internet Gateway:
  route {
    cidr_block = "0.0.0.0/0" # All traffic
    gateway_id = aws_internet_gateway.fastApi_igw.id
  }
}
resource "aws_route_table_association" "public_assocRT_1" {
  subnet_id      = aws_subnet.this["fastApi_sn_public_1"].id
  route_table_id = aws_route_table.fastApi_public_rt.id
}
resource "aws_route_table_association" "public_assocRT_2" {
  subnet_id      = aws_subnet.this["fastApi_sn_public_2"].id
  route_table_id = aws_route_table.fastApi_public_rt.id
}


resource "aws_route_table" "fastApi_private_rt_1" {
  vpc_id = aws_vpc.fastApi_vpc.id

  # Send all internet traffic (0.0.0.0/0) to the NAT Gateway:
  route {
    cidr_block     = "0.0.0.0/0" # All traffic
    nat_gateway_id = aws_nat_gateway.fastApi_ng_1.id
  }
}
resource "aws_route_table_association" "private_assocRT_1" {
  subnet_id      = aws_subnet.this["fastApi_sn_private_1"].id
  route_table_id = aws_route_table.fastApi_private_rt_1.id
}

resource "aws_route_table" "fastApi_private_rt_2" {
  vpc_id = aws_vpc.fastApi_vpc.id

  # Send all internet traffic (0.0.0.0/0) to the NAT Gateway:
  route {
    cidr_block     = "0.0.0.0/0" # All traffic
    nat_gateway_id = aws_nat_gateway.fastApi_ng_2.id
  }
}
resource "aws_route_table_association" "private_assocRT_2" {
  subnet_id      = aws_subnet.this["fastApi_sn_private_2"].id
  route_table_id = aws_route_table.fastApi_private_rt_2.id
}
