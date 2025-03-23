output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_vpc_id" {
  value = var.vpc_id
}

output "eks_subnet_ids" {
  value = var.subnet_ids
}