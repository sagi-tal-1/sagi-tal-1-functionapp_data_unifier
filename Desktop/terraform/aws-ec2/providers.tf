terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}