resource "aws_api_gateway_account" "main" {
    cloudwatch_role_arn = var.cloudwatch_role_arn
}

resource "aws_api_gateway_rest_api" "weather_api" {
  name = "weather-api-test"
}

resource "aws_api_gateway_resource" "weather_resource" {

  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "weather-api-test"
  
}

resource "aws_api_gateway_method" "get_weather" {

  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.weather_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {

  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  resource_id = aws_api_gateway_resource.weather_resource.id
  http_method = aws_api_gateway_method.get_weather.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {

  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_stage" "name" {

  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  stage_name = "prod"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    caller         = "$context.identity.caller"
    user           = "$context.identity.user"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    resourcePath   = "$context.resourcePath"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    errorMessage   = "$context.error.message"
    integrationLatency = "$context.integrationLatency"
    responseLatency    = "$context.responseLatency"
    xrayTraceId        = "$context.xrayTraceId"
    })
  }
  
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/weather-api"
  retention_in_days = 14
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  stage_name  = aws_api_gateway_stage.name.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"   # Use "ERROR" in prod to reduce noise
    data_trace_enabled = true     # Logs full request/response — disable if handling sensitive data
  }
}