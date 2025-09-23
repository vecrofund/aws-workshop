terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"  
}


data "aws_availability_zones" "case2-azs" {
  state = "available"
  
}

data "aws_ami" "amzonami" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "case2-vpc" {
    tags = {
      Name = "case2-vpc"
    }
    cidr_block = var.aws_vpc_cidr
    enable_dns_support   = true
    
}
resource "aws_internet_gateway" "case2-igw" {
    vpc_id = aws_vpc.case2-vpc.id
    tags = {
      Name = "case2-igw"
    }
  
}
resource "aws_subnet" "case2-subnet" {
    count = length(data.aws_availability_zones.case2-azs.names)
    vpc_id = aws_vpc.case2-vpc.id
    map_public_ip_on_launch = true
    cidr_block = "10.0.${count.index + 1}.0/24"
    availability_zone = data.aws_availability_zones.case2-azs.names[count.index]
    tags = {
        Name = "case2-subnet-${count.index + 1}"
    }
  
}
resource "aws_route_table" "case2-pub-route-table" {
    vpc_id = aws_vpc.case2-vpc.id
    tags = {
      Name = "case2-pub-route-table"
    } 
}
resource "aws_route" "case2-pub-route" {
    route_table_id         = aws_route_table.case2-pub-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.case2-igw.id
}
resource "aws_route_table_association" "case2-pub-subnet-assoc" {
    count = length(data.aws_availability_zones.case2-azs.names)
    subnet_id      = aws_subnet.case2-subnet[count.index].id
    route_table_id = aws_route_table.case2-pub-route-table.id
}

resource "aws_security_group" "case2-sg-ec2" {
    name        = "case2-sg-ec2"
    description = "Allow traffic from Load Balancer"
    vpc_id      = aws_vpc.case2-vpc.id
    tags = {
      Name = "case2-sg-ec2"
    }
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}