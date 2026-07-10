output "eks_cluster_sg_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "eks_node_sg_id" {
  value = aws_security_group.eks_node_sg.id
}