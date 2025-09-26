resource "aws_lambda_function" "lambda-ms1" {
    function_name = "lambda-ms1"
    filename      = data.archive_file.lambdazip.output_path
    role          = aws_iam_role.case10-lambda-iam-role.arn
    # handler is always like filename.functionname
    handler       = "app.handlerone"
    source_code_hash = data.archive_file.lambdazip.output_base64sha256
    runtime       = "python3.12"
    timeout       = 30
    memory_size   = 512
  
}



resource "aws_iam_role" "case10-lambda-iam-role" {
  name = "case10-lambda-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

}
resource "aws_iam_role_policy_attachment" "case10-attach-policy" {
  role       = aws_iam_role.case10-lambda-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}