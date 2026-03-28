output "gateway_invocation_url" {
  value = module.gateway.gateway_invocation_url
}

output "s3_bucket_uri" {
  value=module.aws_s3_bucket.bucket_uri
}

output "aws_cloudfront_distribution_id" {
  value=module.cloudfront.aws_cloudfront_distribution_id
}