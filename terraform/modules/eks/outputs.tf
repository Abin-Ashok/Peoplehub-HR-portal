output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster certificate authority"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "node_group_name" {
  description = "Name of the managed EKS node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  description = "ARN of the EKS worker node IAM role"
  value       = aws_iam_role.node.arn
}

output "cluster_security_group_id" {
  description = "Security group ID used for EKS cluster and managed-node communication"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
