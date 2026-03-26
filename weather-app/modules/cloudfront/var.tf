variable "s3_domain_name" {
    type=string
    description = "S3 domain name"
}

variable "cloudfront_alternate_domain" {
   type=string
   description="provide the website url here"
}

variable "aws_acm_certificate_validation_arn" {
  type=string
  description = "certificate validation arn"
}

variable "aws_cloudwatch_distribution_arn" {
  type=string
  description = "cloudfromt arn"
}