
output "alb_security_group_id" {
  value = aws_security_group.public_alb.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "internal_alb_security_group_id" {
  value = aws_security_group.internal_alb.id
}


output "rds_security_group_id" {
  value = try(aws_security_group.rds[0].id, null)
}
output "jenkins_security_group_id" {
  description = "Jenkins EC2 security group ID"
  value       = aws_security_group.jenkins.id
}