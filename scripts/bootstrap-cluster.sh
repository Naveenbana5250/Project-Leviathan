#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"

CLUSTER="$(terraform -chdir="$TF" output -raw cluster_name)"
CILIUM_ROLE_ARN="$(terraform -chdir="$TF" output -raw cilium_operator_role_arn)"

printf 'Cluster: %s\n' "$CLUSTER"
echo "Waiting for initial EKS managed node to appear..."
for i in {1..60}; do
  if kubectl get nodes >/dev/null 2>&1 && [[ "$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]]; then
    break
  fi
  sleep 10
done
kubectl get nodes -o wide

echo "Patching aws-node so Cilium can take over ENI/IPAM management..."
kubectl -n kube-system patch daemonset aws-node --type='strategic' \
  -p='{"spec":{"template":{"spec":{"nodeSelector":{"io.cilium/aws-node-enabled":"true"}}}}}'

VALUES_FILE="$(mktemp)"
trap 'rm -f "$VALUES_FILE"' EXIT
cat > "$VALUES_FILE" <<VALUES
# EKS / AWS ENI mode

eni:
  enabled: true
  iamRole: "${CILIUM_ROLE_ARN}"
ipam:
  mode: eni
operator:
  replicas: 1
prometheus:
  enabled: true
VALUES

echo "Installing Cilium 1.20.2 in AWS ENI mode..."
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install cilium cilium/cilium \
  --version 1.20.2 \
  --namespace kube-system \
  --values "$VALUES_FILE" \
  --wait --timeout 15m

echo "Waiting for Cilium..."
kubectl -n kube-system rollout status ds/cilium --timeout=10m
kubectl -n kube-system rollout status deployment/cilium-operator --timeout=10m

echo "Restarting CoreDNS so it is recreated under the final CNI..."
kubectl -n kube-system rollout restart deployment/coredns || true
kubectl -n kube-system rollout status deployment/coredns --timeout=10m || true

echo "Waiting for nodes Ready under Cilium..."
kubectl wait --for=condition=Ready nodes --all --timeout=10m

echo "Installing Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --version 10.9.2 \
  --namespace argocd \
  --create-namespace \
  --set global.networkPolicy.create=false \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=true \
  --wait --timeout 15m

echo "Cluster bootstrap complete."
echo
kubectl get nodes -o wide
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n argocd get pods
