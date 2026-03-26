output "cloudwatch_policy_arn" {
  value=aws_iam_role.cloudwatch_role.arn
}

output "cloudwatch_role_policy_attachment" {
  value = aws_iam_role_policy_attachment.cloudwath_policy_attachment
}