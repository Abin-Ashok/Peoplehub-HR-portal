output "vpc_id" {
  description = "ID of the PeopleHub VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets for the ALB"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets for frontend EC2 and EKS"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets for RDS"
  value       = aws_subnet.private_db[*].id
}