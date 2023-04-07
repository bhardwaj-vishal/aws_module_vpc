# Creating VPC

resource "aws_vpc" "vpc" {
  count                = var.vpc-enabled ? 1 : 0
  cidr_block           = var.vpc-cidr
  instance_tenancy     = var.instance-tenancy
  enable_dns_support   = var.enable-dns-support
  enable_dns_hostnames = var.enable-dns-hostnames
  tags = merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "vpc")})) 
}


data "aws_availability_zones" "azs" {
  state = "available"
}

# Public Subnets

resource "aws_subnet" "public-subnets" {
  count                   = var.vpc-enabled && length(var.vpc-public-subnet-cidr) > 0 ? length(var.vpc-public-subnet-cidr) : 0
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  cidr_block              = var.vpc-public-subnet-cidr[count.index]
  vpc_id                  = aws_vpc.vpc[0].id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = merge(var.common_tags, tomap({Name = "${format("%s-%s-%s", var.prefix, "pub-sub", count.index + 1)}"})) 
}


# Public Routes

resource "aws_route_table" "public-routes" {
  vpc_id = aws_vpc.vpc[0].id
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.igw[0].id
  # }
  
  tags = merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "rt_pub")})) 
  
}

# Associate/Link Public-Route With Public-Subnets

resource "aws_route_table_association" "public-association" {
  count          = var.vpc-enabled && length(var.vpc-public-subnet-cidr) > 0 ? length(var.vpc-public-subnet-cidr) : 0
  route_table_id = aws_route_table.public-routes.id
  subnet_id      = aws_subnet.public-subnets.*.id[count.index]
}

# Private Subnet

resource "aws_subnet" "private-subnets" {
  count             = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = var.vpc-private-subnet-cidr[count.index]
  vpc_id            = aws_vpc.vpc[0].id
  tags = merge(var.common_tags, tomap({Name = "${format("%s-%s-%s", var.prefix, "app-sub", count.index + 1)}"})) 
}


# Private Route-Table For Private-Subnets

resource "aws_route_table" "private-routes" {
  #count  = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  vpc_id = aws_vpc.vpc[0].id
  # route {
  #   cidr_block     = var.private-route-cidr
  #   nat_gateway_id = element(aws_nat_gateway.ngw.*.id,count.index)
  # }
  tags =  merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "rt_private")})) 


}

# Associate/Link Private-Routes With Private-Subnets

resource "aws_route_table_association" "private-routes-linking" {
  count          = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  subnet_id      = aws_subnet.private-subnets.*.id[count.index]
  route_table_id = aws_route_table.private-routes.id
}


# K8s Subnet

resource "aws_subnet" "k8s-subnets" {
  count             = var.vpc-enabled && length(var.vpc-k8s-subnet-cidr) > 0 ? length(var.vpc-k8s-subnet-cidr) : 0
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = var.vpc-k8s-subnet-cidr[count.index]
  vpc_id            = aws_vpc.vpc[0].id
  tags = merge(var.common_tags, tomap({Name = "${format("%s-%s-%s", var.prefix, "k8s-sub", count.index + 1)}"})) 
}

# Database subnet

resource "aws_subnet" "database-subnets" {
  count             = var.vpc-enabled && length(var.vpc-db-subnet-cidr) > 0 ? length(var.vpc-db-subnet-cidr) : 0
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = var.vpc-db-subnet-cidr[count.index]
  vpc_id            = aws_vpc.vpc[0].id
  tags = merge(var.common_tags, tomap({Name = "${format("%s-%s-%s", var.prefix, "app-sub", count.index + 1)}"})) 
}