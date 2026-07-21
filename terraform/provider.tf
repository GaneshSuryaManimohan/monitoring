terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
  backend "s3" {
    bucket         = "backend-remote-s3-bucket"
    key            = "monitoring-remote-state"
    region         = "us-east-1"
    dynamodb_table = "s3-bucket-locking"
  }
}

provider "aws" {
  region = "us-east-1"
}