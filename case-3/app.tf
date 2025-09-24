resource "aws_instance" "app" {
  ami           = data.aws_ami.amzonami.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.case3-private-subnet[0].id
  security_groups = [aws_security_group.case3-private-app.id]
  user_data = file("user_data_app.sh")
  key_name = "awsdev"
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    delete_on_termination = true
  }
  iam_instance_profile = aws_iam_instance_profile.case3-iam-instance-profile.name
  tags = {
    Name = "case3-application-server"
  }
}