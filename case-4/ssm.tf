resource "aws_iam_instance_profile" "case4-iam-instance-profile" {
  name = "case4-iam-instance-profile"
  role = aws_iam_role.case4-ec2-iam-role.name
}
resource "aws_iam_role" "case4-ec2-iam-role" {
  name = "case4-ec2-iam-role"
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
resource "aws_iam_role_policy_attachment" "case4-attach-policy" {
  role       = aws_iam_role.case4-ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}