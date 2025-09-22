variable "aws_regionname" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"  
}
variable "aws_vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
  
}