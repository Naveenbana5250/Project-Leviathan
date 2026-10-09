# IRSA roles for in-cluster components. No static AWS keys are placed inside
# Kubernetes or GitHub.

data "aws_iam_policy_document" "cilium_operator_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:cilium-operator"]
    }
  }
}

resource "aws_iam_role" "cilium_operator" {
  name               = "leviathan-cilium-operator"
  assume_role_policy = data.aws_iam_policy_document.cilium_operator_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cilium_operator_eni" {
  statement {
    sid    = "CiliumENIManagement"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateTags",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cilium_operator_eni" {
  name   = "leviathan-cilium-eni"
  role   = aws_iam_role.cilium_operator.id
  policy = data.aws_iam_policy_document.cilium_operator_eni.json
}

data "aws_iam_policy_document" "kyverno_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kyverno:kyverno-admission-controller"]
    }
  }
}

resource "aws_iam_role" "kyverno_ecr" {
  name               = "leviathan-kyverno-ecr"
  assume_role_policy = data.aws_iam_policy_document.kyverno_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "kyverno_ecr_read" {
  statement {
    sid       = "ECRAuthorization"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadLeviathanImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [for repo in aws_ecr_repository.app : repo.arn]
  }
}

resource "aws_iam_role_policy" "kyverno_ecr_read" {
  name   = "leviathan-ecr-read"
  role   = aws_iam_role.kyverno_ecr.id
  policy = data.aws_iam_policy_document.kyverno_ecr_read.json
}
