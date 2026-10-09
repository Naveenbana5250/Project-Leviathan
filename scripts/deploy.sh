#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"

export AWS_PROFILE="${AWS_PROFILE:-leviathan-admin}"
export AWS_REGION="${AWS_REGION:-ap-south-1}"

"$ROOT/scripts/preflight.sh"

echo
echo "=== 1/5 Terraform: AWS VPC + EKS + ECR + IAM/OIDC ==="
terraform -chdir="$TF" init
if [[ -f "$TF/leviathan.tfplan" ]]; then
  echo "Using the reviewed Terraform plan at terraform/leviathan.tfplan"
  terraform -chdir="$TF" apply leviathan.tfplan
else
  echo "No saved plan found. Terraform will show an interactive plan before applying."
  terraform -chdir="$TF" apply
fi

CLUSTER="$(terraform -chdir="$TF" output -raw cluster_name)"
ROLE_ARN="$(terraform -chdir="$TF" output -raw github_actions_role_arn)"

echo
echo "=== 2/5 Configure kubectl ==="
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER" --profile "$AWS_PROFILE"

echo
echo "=== 3/5 Replace AWS VPC CNI with Cilium ENI mode ==="
"$ROOT/scripts/bootstrap-cluster.sh"

echo
echo "=== 4/5 Render dynamic GitOps IAM values ==="
"$ROOT/scripts/render-infra-values.sh"

echo
echo "=== 5/5 Configure GitHub Actions variable ==="
gh variable set AWS_ROLE_ARN --body "$ROLE_ARN"

echo
echo "AWS infrastructure and cluster bootstrap are complete."
echo "Kyverno IRSA role has been rendered into gitops/apps/10-kyverno.yaml."
echo "NEXT: commit/push this repository, then apply the Argo root app after the first signed images exist."
echo
echo "Run:"
echo "  git add . && git commit -m 'Bootstrap AWS Leviathan' && git push"
echo
echo "After build-sign workflow succeeds:"
echo "  ./scripts/render-demo-images.sh"
echo "  git add gitops/demo-app/base/app.yaml && git commit -m 'Pin signed ECR images' && git push"
echo "  kubectl apply -f gitops/bootstrap/root-app.yaml"
