output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster_role.arn
  description = "The ARN of the EKS Cluster IAM Role"
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node_role.arn
  description = "The ARN of the EKS Node Group IAM Role"
}
