variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the frontend Application Load Balancer"
  type        = string
}
