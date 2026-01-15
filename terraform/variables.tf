variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "epos-platform-demo"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "your-name"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "node_instance_types" {
  description = "Node group instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "single_nat_gateway" {
  description = "Use 1 NAT (cheaper) vs 1 per AZ (more resilient)"
  type        = bool
  default     = true
}
