module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.public_access_cidrs
  endpoint_private_access      = true

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  # Avoid creating a customer-managed KMS key for this short-lived lab.
  encryption_config = null

  # Keep only the useful audit log for this temporary lab.
  enabled_log_types                      = ["audit"]
  cloudwatch_log_group_retention_in_days = 1

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # VPC CNI is required temporarily so the EKS managed node can bootstrap.
  # Cilium later takes over ENI/IPAM management.
  addons = {
    vpc-cni = {
      before_compute              = true
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    coredns = {
      most_recent = true

      # Allow CoreDNS to schedule while the node has the
      # Cilium agent-not-ready bootstrap taint.
      configuration_values = jsonencode({
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          },
          {
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          },
          {
            key               = "node.kubernetes.io/not-ready"
            operator          = "Exists"
            effect            = "NoExecute"
            tolerationSeconds = 300
          },
          {
            key               = "node.kubernetes.io/unreachable"
            operator          = "Exists"
            effect            = "NoExecute"
            tolerationSeconds = 300
          },
          {
            key      = "node.cilium.io/agent-not-ready"
            operator = "Exists"
            effect   = "NoExecute"
          }
        ]
      })

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    kube-proxy = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    leviathan = {
      name = "leviathan-workers"

      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = var.node_disk_size_gb
      ami_type  = "AL2023_x86_64_STANDARD"

      labels = {
        "leviathan.io/role" = "security-lab"
      }

      # Keep workloads away from the node until Cilium is ready.
      taints = {
        cilium = {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }

      # Temporary AWS VPC CNI permissions needed while the node bootstraps.
      iam_role_additional_policies = {
        bootstrap_vpc_cni = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      }
    }
  }

  tags = local.common_tags
}
