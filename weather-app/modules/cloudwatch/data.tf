data "aws_iam_policy_document" "cloudwatch_role_permission" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type="Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}