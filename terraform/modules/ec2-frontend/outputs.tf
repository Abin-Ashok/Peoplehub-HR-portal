output "launch_template_id" {
  description = "ID of the frontend EC2 launch template"
  value       = aws_launch_template.frontend.id
}

output "autoscaling_group_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}

output "autoscaling_group_arn" {
  description = "ARN of the frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.arn
}
