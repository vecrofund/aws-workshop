terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
}

data "aws_availability_zones" "all-azs" {
    state = "available"
  
}