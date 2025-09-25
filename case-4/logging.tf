resource "aws_cloudwatch_log_group" "case4-log-group" {
  name = "case4-log-group"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "case4-log-stream" {
  name           = "case4-log-stream"
  log_group_name = aws_cloudwatch_log_group.case4-log-group.name
}


resource "aws_iam_role" "case4-vpc-flow-log-role" {
  name = "case4-vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      },
    ]
  })
  
}
resource "aws_iam_role_policy" "case4-vpc-flow-log-policy" {
  role = aws_iam_role.case4-vpc-flow-log-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



resource "aws_flow_log" "case4-flow-log" {
    iam_role_arn = aws_iam_role.case4-vpc-flow-log-role.arn
    log_destination_type = "cloud-watch-logs"
  log_destination = aws_cloudwatch_log_group.case4-log-group.arn
  traffic_type         = "ALL"
  vpc_id              = aws_vpc.case4-vpc-1.id
}