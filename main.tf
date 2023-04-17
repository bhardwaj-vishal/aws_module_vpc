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

# Creating an Internet Gateway

resource "aws_internet_gateway" "igw" {
  count = var.vpc-enabled && length(var.vpc-public-subnet-cidr) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id

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
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.igw[0].id
   }
  
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

# Elastic IP For NAT-Gate Way

resource "aws_eip" "eip-ngw" {
  count = var.vpc-enabled && var.total-nat-gateway-required > 0 ?  var.total-nat-gateway-required : 0

}

# Creating NAT Gateways In Public-Subnets, Creating single NAT Gateway for both Az

resource "aws_nat_gateway" "ngw" {
  count         = var.vpc-enabled && var.total-nat-gateway-required > 0 ? var.total-nat-gateway-required : 0
  allocation_id = aws_eip.eip-ngw.*.id[count.index]
  subnet_id     = aws_subnet.public-subnets.*.id[count.index]

}

# Private Route-Table For Private-Subnets

resource "aws_route_table" "private-routes" {
  #count  = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  vpc_id = aws_vpc.vpc[0].id
  route {
    cidr_block     = var.private-route-cidr
    nat_gateway_id = aws_nat_gateway.ngw[0].id
  }
  tags =  merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "rt_private_app")})) 


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

# Private Route-Table For K8s-Private-Subnets

resource "aws_route_table" "k8s-private-routes" {
  #count  = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  vpc_id = aws_vpc.vpc[0].id
  route {
    cidr_block     = var.private-route-cidr
    nat_gateway_id = aws_nat_gateway.ngw[0].id
  }
  tags =  merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "rt_private_k8s")})) 
}

# Associate/Link K8s-Private-Routes With K8s-Private-Subnets

resource "aws_route_table_association" "k8s-private-routes-linking" {
  count          = var.vpc-enabled && length(var.vpc-k8s-subnet-cidr) > 0 ? length(var.vpc-k8s-subnet-cidr) : 0
  subnet_id      = aws_subnet.k8s-subnets.*.id[count.index]
  route_table_id = aws_route_table.k8s-private-routes.id
}
# Database subnet

resource "aws_subnet" "database-subnets" {
  count             = var.vpc-enabled && length(var.vpc-db-subnet-cidr) > 0 ? length(var.vpc-db-subnet-cidr) : 0
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = var.vpc-db-subnet-cidr[count.index]
  vpc_id            = aws_vpc.vpc[0].id
  tags = merge(var.common_tags, tomap({Name = "${format("%s-%s-%s", var.prefix, "db-sub", count.index + 1)}"})) 
}

# Private Route-Table For Database-Private-Subnets

resource "aws_route_table" "db-private-routes" {
  #count  = var.vpc-enabled && length(var.vpc-private-subnet-cidr) > 0 ? length(var.vpc-private-subnet-cidr) : 0
  vpc_id = aws_vpc.vpc[0].id
  route {
    cidr_block     = var.private-route-cidr
    nat_gateway_id = aws_nat_gateway.ngw[0].id
  }
  tags =  merge(var.common_tags, tomap({Name = format("%s-%s", var.prefix, "rt_private_db")})) 
}

# Associate/Link Database-Private-Routes With Database-Private-Subnets

resource "aws_route_table_association" "db-private-routes-linking" {
  count          = var.vpc-enabled && length(var.vpc-db-subnet-cidr) > 0 ? length(var.vpc-db-subnet-cidr) : 0
  subnet_id      = aws_subnet.database-subnets.*.id[count.index]
  route_table_id = aws_route_table.db-private-routes.id
}

