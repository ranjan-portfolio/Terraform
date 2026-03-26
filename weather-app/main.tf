
module "aws_s3_bucket" {
  source                = "./modules/s3"
  bucket_name           = "weather-app-bucket"
  cloudfront_domain_arn = module.cloudfront.cloudfront_domain_arn
}

module "cloudfront" {
  source                             = "./modules/cloudfront"
  s3_domain_name                     = module.aws_s3_bucket.bucket_domain_name
  cloudfront_alternate_domain        = "test.rancher-ranjanaws.com"
  aws_acm_certificate_validation_arn = module.weatherapp_certificate.cert_validation_arn
  aws_cloudwatch_distribution_arn = module.cloudwatch.cloudwatch_policy_arn
}


module "weatherapp_dns" {
  source            = "./modules/dns"
  hosted_zone       = "rancher-ranjanaws.com"
  weatherapp_record = "test.rancher-ranjanaws.com"
  weatherapp_ttl    = 60
  weatherapp_value  = [module.cloudfront.cloudfront_domain_name] //cloudfront dmain name needs to go here
}

module "weatherapp_certificate" {
  source = "./modules/acm"
  providers = {
    aws           = aws           # The default (eu-west-2)
    aws.us_east_1 = aws.us_east_1 # The alias you created
  }
  domain_name = "test.rancher-ranjanaws.com"
}



module "gateway" {
  source            = "./modules/gateway"
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  cloudwatch_role_arn = module.cloudwatch.cloudwatch_policy_arn
}

module "lambda" {
  source                = "./modules/lambda"
  gateway_execution_arn = module.gateway.gateway_execution_arn
}

module "cloudwatch"{
  source="./modules/cloudwatch"
}
