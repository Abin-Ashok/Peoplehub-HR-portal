variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the EKS cluster will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for EKS"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR ranges allowed to access the public Kubernetes API endpoint"
  type        = list(string)
  default     = []
}
