variable "bucket_name"{
    description = "Name of the bucket hosting static page"
    type=string
}

variable "cloudfront_domain_arn" {
   description = "This arn of cloudfront required for OAI access"
   type=string
}