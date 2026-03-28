output "bucket" {
  value=aws_s3_bucket.bucket.id
}

output "bucket_domain_name"{
  value=aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "bucket_uri" {
  value="s3://${aws_s3_bucket.bucket.bucket}"
}
