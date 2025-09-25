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
    Name = "customer-location-vm"
  }
  iam_instance_profile = aws_iam_instance_profile.case4-iam-instance-profile.name

}