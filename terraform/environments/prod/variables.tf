variable "project_name" {
  description = "Project name"
  type        = string
  default     = "peoplehub"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the network"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = true
}