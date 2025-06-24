output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "github_runner_public_ip" {
  value = aws_instance.github_runner.public_ip
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
