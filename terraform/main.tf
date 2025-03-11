# provider "aws" {
#   region = "us-east-1"  # Adjust as needed
# }

# ###############################
# # VPC & Networking Resources  #
# ###############################

# # Create a custom VPC
# resource "aws_vpc" "eks_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "eks-vpc"
#   }
# }

# # Create two public subnets in different AZs
# resource "aws_subnet" "eks_subnet_a" {
#   vpc_id                  = aws_vpc.eks_vpc.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-east-1a"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-subnet-a"
#   }
# }

# resource "aws_subnet" "eks_subnet_b" {
#   vpc_id                  = aws_vpc.eks_vpc.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-subnet-b"
#   }
# }

# # Create an Internet Gateway
# resource "aws_internet_gateway" "eks_igw" {
#   vpc_id = aws_vpc.eks_vpc.id

#   tags = {
#     Name = "eks-igw"
#   }
# }

# # Create a Route Table
# resource "aws_route_table" "eks_rt" {
#   vpc_id = aws_vpc.eks_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.eks_igw.id
#   }

#   tags = {
#     Name = "eks-rt"
#   }
# }

# # Associate Route Table with Subnets
# resource "aws_route_table_association" "eks_rt_assoc_a" {
#   subnet_id      = aws_subnet.eks_subnet_a.id
#   route_table_id = aws_route_table.eks_rt.id
# }

# resource "aws_route_table_association" "eks_rt_assoc_b" {
#   subnet_id      = aws_subnet.eks_subnet_b.id
#   route_table_id = aws_route_table.eks_rt.id
# }

# ###############################
# # IAM Roles & Policies        #
# ###############################

# # Check if IAM Role Exists for EKS Cluster
# data "aws_iam_role" "eks_cluster_role" {
#   name = "eks-cluster-role"
# }

# # Create IAM Role for EKS Cluster only if it doesn't exist
# resource "aws_iam_role" "eks_cluster_role" {
#   count = length(data.aws_iam_role.eks_cluster_role.arn) > 0 ? 0 : 1

#   name = "eks-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action    = "sts:AssumeRole",
#       Principal = { Service = "eks.amazonaws.com" },
#       Effect    = "Allow",
#       Sid       = ""
#     }]
#   })

#   tags = {
#     Name = "eks-cluster-role"
#   }
# }

# # Attach IAM Policies to Cluster Role
# resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attach" {
#   count      = length(data.aws_iam_role.eks_cluster_role.arn) > 0 ? 0 : 1
#   role       = aws_iam_role.eks_cluster_role[0].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# # Check if IAM Role Exists for EKS Node Group
# data "aws_iam_role" "eks_node_role" {
#   name = "eks-node-role"
# }

# # Create IAM Role for EKS Node Group only if it doesn't exist
# resource "aws_iam_role" "eks_node_role" {
#   count = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1

#   name = "eks-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action    = "sts:AssumeRole",
#       Principal = { Service = "ec2.amazonaws.com" },
#       Effect    = "Allow",
#       Sid       = ""
#     }]
#   })

#   tags = {
#     Name = "eks-node-role"
#   }
# }

# # Attach Policies to EKS Node Role
# resource "aws_iam_role_policy_attachment" "eks_node_policy_attach" {
#   count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
#   role       = aws_iam_role.eks_node_role[0].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_node_policy_attach2" {
#   count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
#   role       = aws_iam_role.eks_node_role[0].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_role_policy_attachment" "eks_node_policy_attach3" {
#   count      = length(data.aws_iam_role.eks_node_role.arn) > 0 ? 0 : 1
#   role       = aws_iam_role.eks_node_role[0].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# ###############################
# # EKS Cluster & Node Group    #
# ###############################

# # Create the EKS Cluster
# resource "aws_eks_cluster" "eks_cluster" {
#   name     = "my-eks-cluster"
#   role_arn = data.aws_iam_role.eks_cluster_role.arn
#   version  = "1.24"

#   vpc_config {
#     subnet_ids              = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
#     endpoint_public_access  = true
#   }

#   depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy_attach]
# }

# # Create the EKS Node Group
# resource "aws_eks_node_group" "eks_node_group" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = "my-node-group"
#   node_role_arn   = data.aws_iam_role.eks_node_role.arn
#   subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
#   instance_types  = ["t3.medium"]

#   scaling_config {
#     min_size     = 1
#     max_size     = 3
#     desired_size = 1
#   }

#   ami_type = "AL2_x86_64"

#   depends_on = [aws_iam_role_policy_attachment.eks_node_policy_attach]
# }

# ###############################
# # Outputs                     #
# ###############################

# output "eks_cluster_name" {
#   value = aws_eks_cluster.eks_cluster.name
# }

# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.eks_cluster.endpoint
# }

# output "eks_vpc_id" {
#   value = aws_vpc.eks_vpc.id
# }

# output "eks_subnet_ids" {
#   value = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
# }


provider "aws" {
  region = "us-east-1"
}

###############################
# Reference Existing IAM Roles #
###############################

# Reference the Existing EKS Cluster Role
data "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"  # Replace with your actual role name
}

# Reference the Existing EKS Node Role
data "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"  # Replace with your actual role name
}

###############################
# Reference Existing Secrets Manager Secret #
###############################

# Reference the Existing Secret for Database Credentials
data "aws_secretsmanager_secret" "recipe_db_secret" {
  name = "recipe-db-credentials"  # Replace with your actual secret name
}

# If the secret does not exist, create it
resource "aws_secretsmanager_secret" "recipe_db_secret" {
  count        = length(data.aws_secretsmanager_secret.recipe_db_secret) > 0 ? 0 : 1
  name         = "recipe-db-credentials"  # Replace with your actual secret name
  description  = "Database credentials for the Recipe Finder application"
  recovery_window_in_days = 7
}

###############################
# VPC & Subnets              #
###############################

# Reference Existing VPC (if required)
data "aws_vpc" "eks_vpc" {
  id = "vpc-04c743847428d6e25"  # Replace with your existing VPC ID
}

# Reference Existing Subnet A
data "aws_subnet" "eks_subnet_a" {
  id = "subnet-00bd253294d9600fa"  # Replace with your existing subnet ID
}

# Reference Existing Subnet B
data "aws_subnet" "eks_subnet_b" {
  id = "subnet-0837b0c7e2596e21f"  # Replace with your existing subnet ID
}

###############################
# Check if EKS Cluster Exists #
###############################

# Check if the EKS Cluster exists
data "aws_eks_cluster" "eks_cluster" {
  name = "my-eks-cluster"  # Replace with your actual cluster name
}

###############################
# Create EKS Cluster if not Exists #
###############################

resource "aws_eks_cluster" "eks_cluster" {
  count    = length(data.aws_eks_cluster.eks_cluster) == 0 ? 1 : 0
  name     = "my-eks-cluster"  # Replace with your actual cluster name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = "1.24"

  vpc_config {
    subnet_ids             = [data.aws_subnet.eks_subnet_a.id, data.aws_subnet.eks_subnet_b.id]
    endpoint_public_access = true
  }

  depends_on = [
    data.aws_iam_role.eks_cluster_role  # Ensuring the IAM role exists before creating the cluster
  ]
}

###############################
# Create EKS Node Group if Cluster Created #
###############################

resource "aws_eks_node_group" "eks_node_group" {
  count        = length(data.aws_eks_cluster.eks_cluster) == 0 ? 1 : 0
  cluster_name = aws_eks_cluster.eks_cluster[0].name
  node_group_name = "my-node-group"
  node_role_arn = data.aws_iam_role.eks_node_role.arn
  subnet_ids    = [data.aws_subnet.eks_subnet_a.id, data.aws_subnet.eks_subnet_b.id]
  instance_types = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 1
  }

  ami_type = "AL2_x86_64"

  depends_on = [
    aws_eks_cluster.eks_cluster,  # Ensuring the EKS cluster exists before creating the node group
    data.aws_iam_role.eks_node_role  # Ensuring the IAM role exists before creating the node group
  ]
}

###############################
# Outputs                    #
###############################

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster[0].name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster[0].endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_cluster[0].arn
}

output "recipe_db_secret_arn" {
  value = aws_secretsmanager_secret.recipe_db_secret[0].arn
}

output "recipe_db_secret_value" {
  value = aws_secretsmanager_secret.recipe_db_secret[0].secret_string
}
