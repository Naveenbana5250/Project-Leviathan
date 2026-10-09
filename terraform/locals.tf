data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = var.cluster_name

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Public-only VPC is intentional for this short-lived, low-budget lab.
  # No NAT Gateway is created. Nodes receive public IPs but have no inbound SSH rule.
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 0),
    cidrsubnet(var.vpc_cidr, 4, 1),
  ]

  common_tags = {
    Project     = "Project-Leviathan"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.github_owner
  }
}
