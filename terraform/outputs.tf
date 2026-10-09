output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}


output "cilium_operator_role_arn" {
  value = aws_iam_role.cilium_operator.arn
}

output "kyverno_ecr_role_arn" {
  value = aws_iam_role.kyverno_ecr.arn
}

output "ecr_repositories" {
  value = {
    for name, repo in aws_ecr_repository.app :
    name => repo.repository_url
  }
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
