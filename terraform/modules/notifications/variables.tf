variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "sender_email" {
  description = "Email address used by Amazon SES for notifications"
  type        = string
}