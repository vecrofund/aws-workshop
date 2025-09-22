terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_regionname  
}

resource "aws_vpc" "case1-vpc" {
    tags = {
        Name = "case1-vpc"
    }
  cidr_block = 
}