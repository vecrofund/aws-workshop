
# creating an public rest api 

resource "aws_api_gateway_rest_api" "ms1-api" {
  name        = "ms1-api"
  description = "Example API Gateway"
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

# creating a resource /data 

resource "aws_api_gateway_resource" "ms1-api-resource" {
  rest_api_id = aws_api_gateway_rest_api.ms1-api.id
  parent_id   = aws_api_gateway_rest_api.ms1-api.root_resource_id
  path_part   = "data"
}

# creating a GET method on /data resource

resource "aws_api_gateway_method" "ms1-api-get-method" {
  rest_api_id   = aws_api_gateway_rest_api.ms1-api.id
  resource_id   = aws_api_gateway_resource.ms1-api-resource.id
  http_method   = "GET"
  authorization = "NONE"
}


resource "aws_api_gateway_method" "ms1-api-POST-method" {
    rest_api_id   = aws_api_gateway_rest_api.ms1-api.id
  resource_id   = aws_api_gateway_resource.ms1-api-resource.id
  http_method   = "POST"
  authorization = "NONE"

}

# integrating the GET method with lambda function

resource "aws_api_gateway_integration" "ms1-api-get-integration" {
  rest_api_id = aws_api_gateway_rest_api.ms1-api.id
  resource_id = aws_api_gateway_resource.ms1-api-resource.id
  http_method = aws_api_gateway_method.ms1-api-get-method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-ms1.invoke_arn
}

# passing post method to lambda function

resource "aws_api_gateway_integration" "ms1-api-post-integration" {
  rest_api_id = aws_api_gateway_rest_api.ms1-api.id
  resource_id = aws_api_gateway_resource.ms1-api-resource.id
  http_method = aws_api_gateway_method.ms1-api-POST-method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-ms1.invoke_arn
}



# create a stage for deployment

resource "aws_api_gateway_stage" "ms1-api-stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.ms1-api.id
  deployment_id = aws_api_gateway_deployment.ms1-api-deployment.id
  xray_tracing_enabled = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.case10_api_gateway_log_group.arn
    format          = "$context.requestId - $context.identity.sourceIp - $context.httpMethod $context.resourcePath $context.status $context.protocol"
  }

}

# deploying into a stage  the api

resource "aws_api_gateway_deployment" "ms1-api-deployment" {
  depends_on = [aws_api_gateway_integration.ms1-api-get-integration]
  rest_api_id = aws_api_gateway_rest_api.ms1-api.id
  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_method.ms1-api-get-method.id,
        aws_api_gateway_integration.ms1-api-get-integration.id,
        aws_api_gateway_method.ms1-api-POST-method.id,
        aws_api_gateway_integration.ms1-api-post-integration.id
    ]))
  }
}

# enabling cloudwatch logs for api gateway
resource "aws_api_gateway_account" "ms1-api-account" {
  cloudwatch_role_arn = aws_iam_role.api-gateway-cloudwatch-role.arn
}      

resource "aws_cloudwatch_log_group" "case10_api_gateway_log_group" {
  name = "case10_api_gateway_log_group"
  retention_in_days = 14
}

resource "aws_iam_role" "api-gateway-cloudwatch-role" {
  name = "api-gateway-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

}
resource "aws_iam_role_policy_attachment" "api-gateway-attach-policy" {
  role       = aws_iam_role.api-gateway-cloudwatch-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}   