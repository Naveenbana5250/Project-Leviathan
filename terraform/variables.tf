variable "aws_region" {
  description = "AWS Region for Leviathan."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "leviathan-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Keep this in EKS standard support."
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR used by the dedicated Leviathan VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "node_instance_type" {
  description = "Low-cost worker size that can still run the full demo stack."
  type        = string
  default     = "t3a.xlarge"
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "node_disk_size_gb" {
  type    = number
  default = 50
}

variable "github_owner" {
  description = "GitHub owner used for GitHub Actions OIDC trust."
  type        = string
  default     = "Naveenbana5250"
}

variable "github_owner_id" {
  description = "Immutable GitHub owner ID used in OIDC subject claims."
  type        = string
  default     = "176170264"
}

variable "github_repo_id" {
  description = "Immutable GitHub repository ID used in OIDC subject claims."
  type        = string
  default     = "1411821239"
}

variable "github_repo" {
  description = "GitHub repository used for CI/CD."
  type        = string
  default     = "Project-Leviathan"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the AWS CI role."
  type        = string
  default     = "main"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint. For a short-lived lab, 0.0.0.0/0 is easiest; tighten if possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment" {
  type    = string
  default = "demo"
}
