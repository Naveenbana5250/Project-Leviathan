# Leviathan AWS Runbook

## Phase 0 - Preflight

```bash
./scripts/preflight.sh
```

## Phase 1 - AWS foundation

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
./scripts/plan.sh
```

Review the saved plan. If correct:

```bash
./scripts/deploy.sh
```

Expected AWS resources:
- one VPC
- two public subnets across two AZs
- one EKS control plane
- one EKS managed worker
- three ECR repositories
- one GitHub Actions OIDC provider/role
- security groups/ENIs/EBS created by EKS
- Cilium ENI datapath + Argo CD bootstrap

## Phase 2 - CI/CD

Commit/push. In GitHub Actions, wait for `Build, Push, Keyless Sign`.

Then:

```bash
./scripts/render-demo-images.sh
git add gitops/demo-app/base/app.yaml
git commit -m "Pin signed ECR images"
git push
```

## Phase 3 - GitOps

```bash
kubectl apply -f gitops/bootstrap/root-app.yaml
kubectl -n argocd get applications
```

Wait for apps to become Healthy/Synced.

## Phase 4 - Validation

```bash
./scripts/verify.sh
./scripts/demo.sh
```

## Phase 5 - Destroy

```bash
./scripts/destroy.sh
```
