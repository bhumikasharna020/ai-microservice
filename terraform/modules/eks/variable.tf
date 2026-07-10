variable "environment" {
  description = "value of the environment"
  type        = string
}

variable "project_name" {
  description = "value of the project name"
  type        = string 
}

variable "cluster_version" {
  description = "value of the project name"
  type        = string 
}

variable "node_instance_types" {
  description = "value of the project name"
  type        = list(string)
}

variable "node_desired_size" {
  description = "value of the project name"
  type        = number
}

variable "node_min_size" {
  description = "value of the project name"
  type        = number
}

variable "node_max_size" {
  description = "value of the project name"
  type        = number
}

variable "vpc_id" {
  description = "value of the project name"
  type        = string
  
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_cluster_role_arn" {
  type = string
}

variable "eks_node_role_arn" {
  type = string
}

variable "eks_cluster_sg_id" {
  type = string
}