provider "aws" {
  region = "us-east-1"
}

# ----------------------
# 1. Key Pairs
# ----------------------
resource "aws_key_pair" "github_runner_key" {
  key_name   = "github-runner-key"
  public_key = file("~/.ssh/github-runner-key.pub")
}

resource "aws_key_pair" "worker_node_key" {
  key_name   = "guest-worker-node-key"
  public_key = file("~/.ssh/guest-worker-node-key.pub")
}

# ----------------------
# 2. IAM Roles
# ----------------------

## Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "guest-login-eks-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  ])

  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}

## Node Role
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.eks_node_role.name
  policy_arn = each.value
}

## GitHub Runner Role
resource "aws_iam_role" "github_runner_role" {
  name = "github-runner-role"

  assume_role_policy = data.aws_iam_policy_document.github_runner_assume_role.json
}

resource "aws_iam_role_policy_attachment" "github_runner_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ])

  role       = aws_iam_role.github_runner_role.name
  policy_arn = each.value
}

# ----------------------
# 3. IAM Assume Role Policies
# ----------------------
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "github_runner_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ----------------------
# 4. VPC and Subnets
# ----------------------
resource "aws_vpc" "main" {
  cidr_block = "10.16.0.0/16"
  tags = {
    Name = "guest-login-service-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "guest-login-igw"
  }
}

resource "aws_subnet" "runner_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.16.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "runner-subnet"
  }
}

resource "aws_subnet" "eks_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.16.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.16.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "eks-subnet-2"
  }
}

resource "aws_subnet" "reserved_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.16.4.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "reserved-subnet"
  }
}

# ----------------------
# 5. Route Table for Runner Subnet
# ----------------------
resource "aws_route_table" "rt_runner" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt-runner-subnet"
  }
}

resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.rt_runner.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "runner_assoc" {
  subnet_id      = aws_subnet.runner_subnet.id
  route_table_id = aws_route_table.rt_runner.id
}

# ----------------------
# 6. Security Group for GitHub Runner
# ----------------------
resource "aws_security_group" "github_runner_sg" {
  name   = "github-runner-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "github-runner-sg"
  }
}

# ----------------------
# You can now add aws_eks_cluster and aws_eks_node_group using these values.
# ----------------------