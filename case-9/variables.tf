variable "vpc1" {
  description = "The ID of the first VPC"
  type        = string
  default     = "vpc-1" 
}
variable "vpc2" {
  description = "The ID of the second VPC"
  type        = string
  default     = "vpc-2"
}
variable "vpc1-cidr" {
    description = "The CIDR block for the first VPC"
    type        = string
    default     = "10.10.0.0/16"
  
}
variable "vpc2-cidr" {
    description = "The CIDR block for the second VPC"
    type        = string
    default     = "10.20.0.0/16"
  
}
  