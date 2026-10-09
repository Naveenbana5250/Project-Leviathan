module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs            = local.azs
  public_subnets = local.public_subnets

  # Deliberate lab tradeoff: no NAT Gateway. The worker receives a public IP
  # for outbound package/image access, but no SSH ingress rule is created.
  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_support   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = local.common_tags
}
