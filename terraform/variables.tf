variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "us-east-1"
}


variable "my_ip_cidr" {
  description = "Your IP in CIDR format to allow SSH access (e.g., 203.0.113.25/32)"
  type        = string
}


variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "guest-login-app"
}

variable "node_group_instance_type" {
  description = "EC2 instance type for EKS node group"
  type        = string
  default     = "t3.medium"
}

variable "node_group_desired_capacity" {
  description = "Desired capacity of EKS node group"
  type        = number
  default     = 2
}

variable "node_group_min_capacity" {
  description = "Minimum capacity of EKS node group"
  type        = number
  default     = 1
}

variable "node_group_max_capacity" {
  description = "Maximum capacity of EKS node group"
  type        = number
  default     = 3
}
