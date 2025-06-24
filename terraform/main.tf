# -------------------------------
# VPC Module (Public + Private Subnets)
# -------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "guest-login-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway               = true
  single_nat_gateway               = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
  map_public_ip_on_launch          = true
  manage_default_route_table       = true
  create_igw                       = true

  tags = {
    Project = "guest-login-service"
  }
}

# -------------------------------
# IAM Role for EKS Node Group (with EC2 Connect permissions)
# -------------------------------
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_instance_connect" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2InstanceConnect"
}

# -------------------------------
# Security Group for EKS Node Group (allow SSH)
# -------------------------------
resource "aws_security_group" "eks_nodegroup_sg" {
  name        = "eks-nodegroup-sg"
  description = "Allow SSH inbound to EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# EKS Cluster Module with Managed Node Group using custom IAM Role and SG
# -------------------------------
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"

  cluster_name    = "guest-login-service"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnets  # <-- Using public subnets so nodes get public IPs
  vpc_id          = module.vpc.vpc_id

  enable_irsa     = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
      subnet_ids       = module.vpc.public_subnets

      iam_role_arn         = aws_iam_role.eks_node_group_role.arn
      additional_security_group_ids = [aws_security_group.eks_nodegroup_sg.id]
    }
  }

  tags = {
    Environment = "dev"
    Project     = "guest-login"
  }
}

# -------------------------------
# IAM Role for EC2 (GitHub Runner)
# -------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-github-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_ecr" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_connect" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2InstanceConnect"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-runner-profile"
  role = aws_iam_role.ec2_role.name
}

# -------------------------------
# EC2 Instance for GitHub Runner (EC2 Connect Enabled)
# -------------------------------
resource "aws_instance" "github_runner" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name    = "github-actions-runner"
    Project = "guest-login-service"
  }
}

# -------------------------------
# Get latest Amazon Linux 2 AMI
# -------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------------------------------
# Security Group for EC2 GitHub Runner
# -------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "github-runner-sg"
  description = "Allow SSH and outbound"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
