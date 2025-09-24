resource "aws_ec2_transit_gateway" "case9-tg" {
  description = "case9-tg"
  tags = {
    Name = "case9-tg"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "case9-tg-vpc1-attachment" {
    transit_gateway_id = aws_ec2_transit_gateway.case9-tg.id
    vpc_id             = aws_vpc.case9-vpc-1.id
    subnet_ids         = aws_subnet.case9-vpc1-public-subnet[*].id
    tags = {
        Name = "case9-tg-vpc1-attachment"
    }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "case9-tg-vpc2-attachment" {
    transit_gateway_id = aws_ec2_transit_gateway.case9-tg.id
    vpc_id             = aws_vpc.case9-vpc-2.id
    subnet_ids         = aws_subnet.case9-vpc2-public-subnet[*].id
    tags = {
        Name = "case9-tg-vpc2-attachment"
    }
}