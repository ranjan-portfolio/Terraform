resource "aws_iam_role" "cloudwatch_role" {
  name="cloudwatch_access_role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_role_permission.json

}

resource "aws_iam_role_policy_attachment" "cloudwath_policy_attachment" {
  role=aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}