variable "vpc_cidr" {
  description = "value of the CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "value of the environment"
  type        = string 
}

variable "project_name" {
  description = "value of the project name"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "value of the project name"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "value of the project name"
  type        = list(string)
}

variable "azs" {
  description = "value of the project name"
  type        = list(string)
}
