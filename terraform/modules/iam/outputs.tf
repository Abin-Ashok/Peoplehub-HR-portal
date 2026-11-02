output "frontend_instance_profile_name" {
  description = "Instance profile name for frontend EC2 instances"
  value       = aws_iam_instance_profile.frontend_ec2.name
}

output "frontend_instance_profile_arn" {
  description = "Instance profile ARN for frontend EC2 instances"
  value       = aws_iam_instance_profile.frontend_ec2.arn
}

output "frontend_ec2_role_arn" {
  description = "IAM role ARN assumed by frontend EC2 instances"
  value       = aws_iam_role.frontend_ec2.arn
}

output "jenkins_role_name" {
  description = "IAM role name for the Jenkins EC2 instance"
  value       = aws_iam_role.jenkins.name
}

output "jenkins_role_arn" {
  description = "IAM role ARN for the Jenkins EC2 instance"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_instance_profile_name" {
  description = "Instance profile to attach to the Jenkins EC2 instance"
  value       = aws_iam_instance_profile.jenkins.name
}

output "jenkins_instance_profile_arn" {
  description = "Jenkins EC2 instance profile ARN"
  value       = aws_iam_instance_profile.jenkins.arn
}
output "load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.load_balancer_controller.arn
}