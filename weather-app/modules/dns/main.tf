resource "aws_route53_zone" "main" {
  name = var.hosted_zone
  
}

resource "aws_route53_record" "weather_app_cloudfront_dnsname" {
  zone_id = "Z04014681W7MWNSSOUZXJ"
  name    = var.weatherapp_record
  type    = "CNAME"
  ttl     = var.weatherapp_ttl
  records = var.weatherapp_value
}