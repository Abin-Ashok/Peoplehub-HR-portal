variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private subnet IDs for the database"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group controlling access to MySQL"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial database storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Initial application database name"
  type        = string
  default     = "peoplehub"
}

variable "master_username" {
  description = "RDS master username"
  type        = string
  default     = "peoplehub_admin"
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Protect the production database from accidental deletion"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the database is deleted"
  type        = bool
  default     = false
}
