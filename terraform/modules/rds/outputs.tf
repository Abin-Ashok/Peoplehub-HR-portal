output "db_instance_id" {
  description = "RDS MySQL instance identifier"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "Private RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "MySQL listener port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "PeopleHub database name"
  value       = aws_db_instance.main.db_name
}

output "db_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master credentials"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
