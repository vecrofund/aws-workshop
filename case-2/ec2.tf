resource "aws_instance" "case2-vm" {
  ami           = data.aws_ami.amzonami.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.case2-subnet[0].id
  associate_public_ip_address = true
  key_name = "awsdev"
  security_groups = [aws_security_group.case2-sg-ec2.id]
  tags = {
    Name = "case2-vm"
  }
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  user_data = file("user_data.sh")
  iam_instance_profile = aws_iam_instance_profile.case2-iam-instance-profile.name
  
}

resource "aws_iam_instance_profile" "case2-iam-instance-profile" {
  name = "case2-iam-instance-profile"
  role = aws_iam_role.case2-ec2-iam-role.name
}
resource "aws_iam_role" "case2-ec2-iam-role" {
    name = "case2-ec2-iam-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        },
        ]
    })
  
}
resource "aws_iam_role_policy_attachment" "case2-attach-policy" {
    role       = aws_iam_role.case2-ec2-iam-role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}