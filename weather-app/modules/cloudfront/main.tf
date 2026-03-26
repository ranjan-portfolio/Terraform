
resource "aws_api_gateway_account" "settings" {
    cloudwatch_role_arn = var.aws_cloudwatch_distribution_arn
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name="my-oac"
  description = "cloudfront access to private s3 hosting weather app"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases = [var.cloudfront_alternate_domain]

  origin {
    domain_name              = var.s3_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
    include_cookies = false
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
  # Change this to point to the VALIDATION resource output
    acm_certificate_arn = var.aws_acm_certificate_validation_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "weather-app-cloudfront-logs321"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_bucket_ownership" {
    bucket = aws_s3_bucket.cloudfront_logs.id
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_access" {
   bucket = aws_s3_bucket.cloudfront_logs.id
   block_public_acls = true
   block_public_policy = true
   ignore_public_acls = true
   restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "cloudfront_logs_acl" {
  depends_on = [ aws_s3_bucket_ownership_controls.cloudfront_bucket_ownership,
                 aws_s3_bucket_public_access_block.cloudfront_logs_access ]
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl="private"
  
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}