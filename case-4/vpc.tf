resource "aws_vpc" "case4-vpc-1" {
    cidr_block           = var.vpc1-cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "case4-vpc-1"
    }
}
resource "aws_internet_gateway" "case4-vpc1-igw" {
    vpc_id = aws_vpc.case4-vpc-1.id
    tags = {
        Name = "case4-vpc1-igw"
    }
    
 
}
resource "aws_subnet" "case4-vpc1-public-subnet" {
    count                   = length(data.aws_availability_zones.case4-all-azs.names)
    vpc_id                  = aws_vpc.case4-vpc-1.id
    cidr_block              = "10.0.${count.index+1}.0/24"
    availability_zone       = data.aws_availability_zones.case4-all-azs.names[count.index]
    map_public_ip_on_launch = true
    tags = {
        Name = "case4-vpc1-public-subnet-${count.index + 1}"
    }
  
}
resource "aws_route" "case4-vpc1-public-rt-route" {
    route_table_id         = aws_vpc.case4-vpc-1.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.case4-vpc1-igw.id
}


resource "aws_security_group" "case4-vpc1-sg" {
    name        = "case4-vpc1-sg"
    description = "Security group for VPC 1"
    vpc_id      = aws_vpc.case4-vpc-1.id
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}