variable "lambda_invoke_arn" {
  type=string
  description = "This is the lambda to be invoked from API gateway"
}

variable "cloudwatch_role_arn" {
  type=string
  description = "cloud watch role"
}