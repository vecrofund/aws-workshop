output "stageurl" {
    value = aws_api_gateway_deployment.ms1-api-deployment.invoke_url
  
}