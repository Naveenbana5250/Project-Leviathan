#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"

export AWS_PROFILE="${AWS_PROFILE:-leviathan-admin}"
export AWS_REGION="${AWS_REGION:-ap-south-1}"

echo "This will delete the Leviathan AWS infrastructure."
read -r -p "Type DESTROY to continue: " ans
[[ "$ans" == "DESTROY" ]] || { echo "Cancelled."; exit 1; }

# Best-effort cleanup of Kubernetes LoadBalancer services before VPC deletion.
kubectl delete svc --all -A --field-selector spec.type=LoadBalancer 2>/dev/null || true
sleep 15

terraform -chdir="$TF" destroy

echo
echo "Post-destroy check:"
aws eks list-clusters --region "$AWS_REGION"
aws ec2 describe-nat-gateways --filter State=available --region "$AWS_REGION" --query 'NatGateways[].NatGatewayId'
aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancers[].LoadBalancerArn' 2>/dev/null || true
echo "Review the AWS Billing/Cost Explorer page as a final safety check."
