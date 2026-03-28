
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # This allows the module to accept two versions of the provider
      configuration_aliases = [ aws.us_east_1 ] 
    }
  }
}


resource "aws_wafv2_web_acl" "main" {
  provider = aws.us_east_1
  name     = "cloudfront-waf"
  scope    = "CLOUDFRONT" # Must be CLOUDFRONT

  default_action {
    allow {}
  }

  # 1. AWS Managed Common Rule Set (Standard Protection)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-common-rules"
      sampled_requests_enabled   = true
    }
  }

    # 2. Amazon IP Reputation List (Blocks known malicious IPs)
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 15 # Between your Common Rule (10) and Rate Limit (20)

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-ip-reputation"
      sampled_requests_enabled   = true
    }
  }


  # 2. Rate Limiting (Prevents DDoS/Bill Shock)
  rule {
    name     = "IPRateLimit"
    priority = 20

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ip-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf-main"
    sampled_requests_enabled   = true
  }
}
