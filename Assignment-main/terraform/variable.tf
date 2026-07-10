variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "value of the CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "value of the project name"
  type        = string
  default     = "ai-microservice"
}

variable "environment" {
  description = "value of the environment"
  type        = string 
  default     = "dev"
}

variable "public_cidr_block" {
  description = "value of the public subnet CIDR block"
  type        = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_cidr_block" {
  description = "value of the public subnet CIDR block"
  type        = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "azs" {
  description = "value of the availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

}