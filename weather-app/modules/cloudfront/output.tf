output "cloudfront_domain_name" {
  value=aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_domain_arn" {
  value=aws_cloudfront_distribution.cdn.arn
}

output "aws_cloudfront_distribution_id" {
  value=aws_cloudfront_distribution.cdn.id
}