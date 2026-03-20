resource "aws_lambda_function" "weather_lambda" {

  function_name = "weather-api-test"

  filename      = "./modules/lambda/function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"

  role = aws_iam_role.lambda_role.arn
}

resource "aws_iam_role" "lambda_role" {

  name = "lambda_api_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_secrets" {
  name = "lambda_secrets_policy"
  role = aws_iam_role.lambda_role.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        
        Resource = "*" 
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Limits access to your specific API
  source_arn = "${var.gateway_execution_arn}/*/*"
}


