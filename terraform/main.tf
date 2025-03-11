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
  region = "us-east-1"  # Adjust as needed
}

###############################
# VPC & Networking Resources  #
###############################

# Create a custom VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

# Create two public subnets in different AZs
resource "aws_subnet" "eks_subnet_a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-a"
  }
}

resource "aws_subnet" "eks_subnet_b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-b"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

# Create a Route Table
resource "aws_route_table" "eks_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-rt"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "eks_rt_assoc_a" {
  subnet_id      = aws_subnet.eks_subnet_a.id
  route_table_id = aws_route_table.eks_rt.id
}

resource "aws_route_table_association" "eks_rt_assoc_b" {
  subnet_id      = aws_subnet.eks_subnet_b.id
  route_table_id = aws_route_table.eks_rt.id
}

###############################
# IAM Roles & Policies        #
###############################

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
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
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
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
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attach2" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attach3" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

###############################
# Secrets Manager Resources   #
###############################

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "recipe_db_secret" {
  name        = "recipe-db-credentials"
  description = "Database credentials for Recipe Finder application"

  tags = {
    Name = "recipe-db-credentials"
  }
}

# Add secret value (username and password for DB, example)
resource "aws_secretsmanager_secret_version" "recipe_db_secret_version" {
  secret_id     = aws_secretsmanager_secret.recipe_db_secret.id
  secret_string = jsonencode({
    DATABASE_URL="postgresql+asyncpg://nandeesh:nandeesh123@database-1.cxm2omoga4r6.us-east-1.rds.amazonaws.com:5432/recipefind"
    SECRET_KEY="5bc7c50b424b658b719ca27c76233fa2b78458124ab54b2007a28308f7b351eb"
    API_KEY="c2927a6f1a064a8fa471e31d4d46269f"
    BASE_URL="https://api.spoonacular.com/recipes"
  })
}

###############################
# EKS Cluster & Node Group    #
###############################

# Create the EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.24"

  vpc_config {
    subnet_ids              = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy_attach]
}

# Create the EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 1
  }

  ami_type = "AL2_x86_64"

  depends_on = [aws_iam_role_policy_attachment.eks_node_policy_attach, aws_iam_role_policy_attachment.eks_node_policy_attach2]
}

###############################
# Outputs                    #
###############################

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}
