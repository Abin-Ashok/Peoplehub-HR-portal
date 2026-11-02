variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ALB target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "frontend_port" {
  description = "Port used by the frontend EC2 application"
  type        = number
  default     = 80
}
