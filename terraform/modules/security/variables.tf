
variable "project_name" {
  type    = string
  default = "peoplehub"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "frontend_port" {
  type    = number
  default = 80
}

variable "backend_port" {
  type    = number
  default = 3000
}

variable "database_port" {
  type     = number
  default  = null
  nullable = true
}

variable "eks_cluster_security_group_id" {
  type = string
}

variable "jenkins_admin_cidr" {
  description = "Trusted public IPv4 CIDR allowed to access Jenkins"
  type        = string
  default     = null
  nullable    = true
}