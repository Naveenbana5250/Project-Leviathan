#!/usr/bin/env bash
set -euo pipefail

echo "=== AWS identity ==="
aws sts get-caller-identity

echo "=== EKS nodes ==="
kubectl get nodes -o wide

echo "=== Cilium ==="
kubectl -n kube-system get ds cilium
kubectl -n kube-system get deploy cilium-operator

echo "=== Argo CD ==="
kubectl -n argocd get pods

echo "=== Leviathan apps ==="
kubectl -n argocd get applications 2>/dev/null || true

echo "=== Pods ==="
kubectl get pods -A

echo "=== Useful port-forwards ==="
echo "Argo CD: kubectl -n argocd port-forward svc/argocd-server 8080:80"
echo "Grafana: kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80"
echo "Neo4j : kubectl -n neo4j port-forward svc/neo4j 7474:7474"
echo "n8n   : kubectl -n n8n port-forward svc/n8n 5678:5678"
