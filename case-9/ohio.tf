provider "aws" {
  region = "us-east-2"
  alias = "ohio"  
}

data "aws_vpc" "ohio-vpc" {
    provider = aws.ohio
    default = true
}

data "aws_subnets" "ohio-subnet-ids" {
    provider = aws.ohio
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.ohio-vpc.id]
    }
}
data "aws_security_group" "default" {
    provider = aws.ohio
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ohio-vpc.id]
  }

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

data "aws_ami" "ohio-amazonami" {
    provider = aws.ohio
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}



resource "aws_instance" "ohio-vm" {
  provider = aws.ohio
  ami           = data.aws_ami.ohio-amazonami.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.ohio-subnet-ids.ids[0]
  security_groups = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  tags = {
    Name = "ohio-vm"
  }
  iam_instance_profile = aws_iam_instance_profile.case9-iam-instance-profile.name
  
}

resource "aws_ec2_transit_gateway" "case9-ohio-tg" {
  provider = aws.ohio
  description = "case9-tg"
  tags = {
    Name = "case9-ohio-tg"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "case9-ohio-tg-vpc-attachment" {
    provider = aws.ohio
    transit_gateway_id = aws_ec2_transit_gateway.case9-ohio-tg.id
    vpc_id             = data.aws_vpc.ohio-vpc.id
    subnet_ids         = [data.aws_subnets.ohio-subnet-ids.ids[0]]
    tags = {
        Name = "case9-ohio-tg-vpc-attachment"
    }
}


resource "aws_ec2_transit_gateway_peering_attachment" "ohio-to-nvirginia" {
    provider = aws.ohio
#   peer_account_id         = aws_ec2_transit_gateway.peer.owner_id
  peer_region             = "us-east-1"
  peer_transit_gateway_id = aws_ec2_transit_gateway.case9-tg.id
  transit_gateway_id      = aws_ec2_transit_gateway.case9-ohio-tg.id

  tags = {
    Name = "TGW Peering Requestor - ohio to nvirginia"
  }
}
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "nvirginia-accepter" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.ohio-to-nvirginia.id

  tags = {
    Name = "Example cross-account attachment"
  }
}

# creating vpc route

resource "aws_route" "ohio-to-vpc1" {
    provider = aws.ohio
    route_table_id         = data.aws_vpc.ohio-vpc.main_route_table_id
    destination_cidr_block = var.vpc1-cidr
    transit_gateway_id     = aws_ec2_transit_gateway.case9-ohio-tg.id 
}

# tg routes
resource "aws_ec2_transit_gateway_route" "ohio-to-vpc1" {
    provider = aws.ohio
    destination_cidr_block = var.vpc1-cidr
    transit_gateway_route_table_id = aws_ec2_transit_gateway.case9-ohio-tg.association_default_route_table_id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.ohio-to-nvirginia.id
}
resource "aws_ec2_transit_gateway_route" "vpc1-to-ohio" {
    destination_cidr_block = data.aws_vpc.ohio-vpc.cidr_block
    transit_gateway_route_table_id = aws_ec2_transit_gateway.case9-tg.association_default_route_table_id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.nvirginia-accepter.id
}