output "gateway_execution_arn" {
  value= aws_api_gateway_rest_api.weather_api.execution_arn
}

output "gateway_invocation_url"{
    value=aws_api_gateway_stage.name.invoke_url
}