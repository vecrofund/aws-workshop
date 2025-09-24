resource "aws_vpc" "case3-vpc" {
    cidr_block           = var.aws_vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "case3-vpc"
    }
}
resource "aws_internet_gateway" "case3-vpc-igw" {
    vpc_id = aws_vpc.case3-vpc.id
    tags = {
        Name = "case3-vpc-igw"
    }
    
 
}
resource "aws_subnet" "case3-public-subnet" {
    count                   = length(data.aws_availability_zones.case3-all-azs.names)
    vpc_id                  = aws_vpc.case3-vpc.id
    cidr_block              = "10.0.${count.index+1}.0/24"
    availability_zone       = data.aws_availability_zones.case3-all-azs.names[count.index]
    map_public_ip_on_launch = true
    tags = {
        Name = "case3-public-subnet-${count.index + 1}"
    }
  
}
resource "aws_subnet" "case3-private-subnet" {
    count                   = length(data.aws_availability_zones.case3-all-azs.names)
    vpc_id                  = aws_vpc.case3-vpc.id
    cidr_block              = "10.0.${count.index + 11}.0/24"
    availability_zone       = data.aws_availability_zones.case3-all-azs.names[count.index]
    map_public_ip_on_launch = false
    tags = {
        Name = "case3-private-subnet-${count.index + 1}"
    }  
    depends_on = [ aws_nat_gateway.case3-nat-gateway ]
}
resource "aws_eip" "case3-nat-eip" {
    vpc = true
    tags = {
        Name = "case3-nat-eip"
    }

  
}
resource "aws_nat_gateway" "case3-nat-gateway" {
    allocation_id = aws_eip.case3-nat-eip.id
    subnet_id    = aws_subnet.case3-public-subnet[0].id
    tags = {
        Name = "case3-nat-gateway"
    }
}



resource "aws_route_table" "case3-public-rt" {
    vpc_id = aws_vpc.case3-vpc.id
    tags = {
        Name = "case3-public-rt"
    }  
}
resource "aws_route" "case3-public-rt-route" {
    route_table_id         = aws_route_table.case3-public-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.case3-vpc-igw.id
}
resource "aws_route_table_association" "case3-public-rt-assoc" {
    count          = length(data.aws_availability_zones.case3-all-azs.names)
    subnet_id      = aws_subnet.case3-public-subnet[count.index].id
    route_table_id = aws_route_table.case3-public-rt.id
}
resource "aws_default_route_table" "case3-default-rt" {
    default_route_table_id = aws_vpc.case3-vpc.default_route_table_id
    tags = {
        Name = "case3-default-rt"
    }
}
resource "aws_route" "case3-nat-gateway-route" {
    route_table_id         = aws_default_route_table.case3-default-rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.case3-nat-gateway.id
}
resource "aws_security_group" "case3-public-lb" {
    vpc_id = aws_vpc.case3-vpc.id
    tags = {
        Name = "case3-public-lb"
    }
    ingress  {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "case3-public-web" {
    vpc_id = aws_vpc.case3-vpc.id
    tags = {
        Name = "case3-public-web"
    }
    ingress  {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [aws_security_group.case3-public-lb.id]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "case3-private-app" {
    vpc_id = aws_vpc.case3-vpc.id
    tags = {
        Name = "case3-private-app"
    }
    ingress {
        from_port   = 22    
        to_port     = 22
        protocol    = "tcp"
        security_groups = [ aws_security_group.case3-public-web.id ]
    }
    ingress  {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        security_groups = [ aws_security_group.case3-public-web.id ]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}