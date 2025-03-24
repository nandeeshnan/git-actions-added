provider "aws" {
  region = "us-east-1"
}


data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}


data "aws_subnet" "existing_subnets" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}


data "aws_route_table" "existing_route_table" {
  filter {
    name   = "route-table-id"
    values = [var.route_table_id]
  }
}


data "aws_internet_gateway" "existing_igw" {
  filter {
    name   = "internet-gateway-id"
    values = [var.internet_gateway_id]
  }
}


data "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
}

# Create IAM Role for EKS Cluster only if it doesn't exist
resource "aws_iam_role" "eks_cluster_role" {
  count = length(data.aws_iam_role.eks_cluster_role.arn) > 0 ? 0 : 1

  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "eks.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })

  tags = {
    Name = "eks-cluster-role"
  }
}

# Attach IAM Policies to Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attach" {
  count      = length(data.aws_iam_role.eks_cluster_role.arn) > 0 ? 0 : 1
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Check if IAM Role Exists for EKS Node Group
data "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
}

# Create IAM Role for EKS Node Group only if it doesn't exist
resource "aws_iam_role" "eks_node_role" {
  count = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1

  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })

  tags = {
    Name = "eks-node-role"
  }
}

# Attach Policies to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_node_policy_attach" {
  count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attach2" {
  count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attach3" {
  count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create the EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = "1.24"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy_attach]
}

# Create the EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 1
  }

  ami_type = "AL2_x86_64"

  depends_on = [aws_iam_role_policy_attachment.eks_node_policy_attach]
}

