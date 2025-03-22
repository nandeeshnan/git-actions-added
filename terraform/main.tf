# provider "aws" {
#   region = "us-east-1"  
# }



# # Create a custom VPC
# resource "aws_vpc" "eks_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "eks-vpc"
#   }
# }

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

# Create a custom VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

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

# Check if IAM Role Exists for EKS Cluster
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
  role_arn = length(data.aws_iam_role.eks_cluster_role.arn) > 0 ? data.aws_iam_role.eks_cluster_role.arn : aws_iam_role.eks_cluster_role[0].arn
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
  node_role_arn   = length(data.aws_iam_role.eks_node_role.arn) > 0 ? data.aws_iam_role.eks_node_role.arn : aws_iam_role.eks_node_role[0].arn
  subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 1
  }

  ami_type = "AL2_x86_64"

  depends_on = [aws_iam_role_policy_attachment.eks_node_policy_attach]
}

# Check if IAM Role Exists for AWS Load Balancer Controller
data "aws_iam_role" "aws_load_balancer_controller_role" {
  count = var.create_load_balancer_controller_role ? 0 : 1
  name  = "aws-load-balancer-controller-role"
}

# Create IAM Role for AWS Load Balancer Controller only if it doesn't exist
resource "aws_iam_role" "aws_load_balancer_controller_role" {
  count = var.create_load_balancer_controller_role ? 1 : 0

  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity",
      Effect    = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
      }
    }]
  })

  tags = {
    Name = "aws-load-balancer-controller-role"
  }
}

# Attach IAM Policies to AWS Load Balancer Controller Role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy_attach" {
  count = var.create_load_balancer_controller_role ? 1 : 0

  role       = aws_iam_role.aws_load_balancer_controller_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerControllerPolicy"
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Deploy the AWS Load Balancer Controller using Helm
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.create_load_balancer_controller_role ? aws_iam_role.aws_load_balancer_controller_role[0].arn : data.aws_iam_role.aws_load_balancer_controller_role[0].arn
  }

  depends_on = [aws_eks_node_group.eks_node_group]
}

# Create a Kubernetes Service Account for the AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.create_load_balancer_controller_role ? aws_iam_role.aws_load_balancer_controller_role[0].arn : data.aws_iam_role.aws_load_balancer_controller_role[0].arn
    }
  }

  depends_on = [aws_eks_node_group.eks_node_group]
}

# Outputs
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "eks_subnet_ids" {
  value = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
}

# # Variable to control whether to create the IAM role
# variable "create_load_balancer_controller_role" {
#   description = "Whether to create the IAM role for the AWS Load Balancer Controller"
#   type        = bool
#   default     = true
# }