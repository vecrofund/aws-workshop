terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_regionname  
}

data "aws_availability_zones" "case1-azs" {
  state = "available"
  
}

resource "aws_vpc" "case1-vpc" {
    tags = {
      Name = "case1-vpc"
    }
    cidr_block = var.aws_vpc_cidr
}
resource "aws_internet_gateway" "case1-igw" {
    vpc_id = aws_vpc.case1-vpc.id
    tags = {
      Name = "case1-igw"
    }
  
}
resource "aws_subnet" "case1-subnet" {
    count = length(data.aws_availability_zones.case1-azs.names)
    vpc_id = aws_vpc.case1-vpc.id
    cidr_block = "10.0.${count.index + 1}.0/24"
    tags = {
        Name = "case1-subnet-${count.index + 1}"
    }
  
}
resource "aws_route_table" "case1-pub-route-table" {
    vpc_id = aws_vpc.case1-vpc.id
    tags = {
      Name = "case1-pub-route-table"
    } 
}
resource "aws_route" "case1-pub-route" {
    route_table_id         = aws_route_table.case1-pub-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.case1-igw.id
}
resource "aws_route_table_association" "case1-pub-subnet-assoc" {
    count = length(data.aws_availability_zones.case1-azs.names)
    subnet_id      = aws_subnet.case1-subnet[count.index].id
    route_table_id = aws_route_table.case1-pub-route-table.id
}
output "subnet_ids" {
  value = aws_subnet.case1-subnet[*].id

  
}