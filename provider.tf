terraform {
  backend "s3" {
    bucket       = "terrafrom-weather-app-backend"
    key          = "terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true # This enables S3 native locking
    encrypt      = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

}