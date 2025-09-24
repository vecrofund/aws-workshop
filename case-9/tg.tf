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
resource "aws_route" "case9-tg-vpc1-to-vpc2" {
    route_table_id         = aws_route_table.case9-vpc1-public-rt.id
    destination_cidr_block = aws_vpc.case9-vpc-2.cidr_block
    transit_gateway_id     = aws_ec2_transit_gateway.case9-tg.id
}
resource "aws_route" "case9-tg-vpc2-to-vpc1" {
    route_table_id         = aws_route_table.case9-vpc2-public-rt.id
    destination_cidr_block = aws_vpc.case9-vpc-1.cidr_block
    transit_gateway_id     = aws_ec2_transit_gateway.case9-tg.id
}