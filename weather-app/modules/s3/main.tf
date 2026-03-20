resource "aws_s3_bucket" "bucket" {
  bucket = "weather-app-bucket-test"
  tags = {
     project_name=var.bucket_name
  }
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket=aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
                        
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket=aws_s3_bucket.bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.bucket.id
  key="index.html"
  source = "${path.module}/index.html"
  content_type = "text/html"
  etag=filemd5("${path.module}/index.html")
}