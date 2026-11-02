variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for frontend Auto Scaling"
  type        = list(string)
}

variable "security_group_id" {
  description = "Frontend security group ID"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN for frontend instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of frontend instances"
  type        = number
  default     = 0
}

variable "desired_capacity" {
  description = "Desired number of frontend instances"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of frontend instances"
  type        = number
  default     = 2
}

variable "instance_profile_name" {
  description = "IAM instance profile attached to frontend EC2 instances"
  type        = string
}
