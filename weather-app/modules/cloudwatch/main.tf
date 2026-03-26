resource "aws_iam_role" "cloudwatch_role" {
  name="cloudwatch_access_role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_role_permission.json

}

resource "aws_iam_role_policy_attachment" "cloudwath_policy_attachment" {
  role=aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_cloudwatch_metric_alarm" "k6_failure_alarm" {
  alarm_name          = "k6-failure-rate-30s"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "30" # High-resolution period
  statistic           = "Average"
  threshold           = "2" # Alarm if > 5% failure
  
  # Crucial for intermittent k6 tests
  treat_missing_data  = "breaching" 
  
  alarm_description   = "Triggered when k6 error rate exceeds 5% in a 30s test"
  alarm_actions       = ["arn:aws:sns:eu-west-2:588578924488:Default_CloudWatch_Alarms_Topic"]
}