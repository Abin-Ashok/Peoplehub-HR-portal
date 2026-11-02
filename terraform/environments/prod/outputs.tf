


output "internal_alb_security_group_id" {
  description = "Security group ID for the internal backend ALB"
  value       = module.security.internal_alb_security_group_id
}
