# START HERE — Project Leviathan AWS/EKS

This package is designed for the new public repository:

`Naveenbana5250/Project-Leviathan`

AWS defaults:

- Region: `ap-south-1` (Mumbai)
- AWS CLI profile: `leviathan-admin`
- EKS cluster: `leviathan-eks`
- One `t3a.xlarge` managed worker initially
- Two Availability Zones
- No NAT Gateway
- Amazon ECR for application images

## 1. Copy this starter into the existing Git repository

Do **not** copy a `.git` directory from anywhere else.

```bash
cd ~/Project-Leviathan
rsync -av /path/to/Project-Leviathan-AWS/ ./
```

## 2. Confirm the correct accounts

```bash
gh api user --jq '.login'
aws sts get-caller-identity
aws configure get region
```

Expected GitHub login: `Naveenbana5250`.
Expected AWS region: `ap-south-1`.

Never commit `~/.aws/credentials`, AWS keys, tokens, Terraform state, kubeconfig,
or OAuth/Vault secrets.

## 3. Create the local Terraform variables file

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

`terraform.tfvars` is deliberately ignored by Git.

For the first bootstrap the EKS public API CIDR is permissive. Once connectivity is
confirmed, replace `0.0.0.0/0` with your current public IP `/32` and re-apply.

## 4. Plan before spending AWS credits

```bash
./scripts/preflight.sh
./scripts/plan.sh
```

Review the plan before applying it. The expected large-cost items are:

- 1 EKS cluster
- 1 managed EC2 worker (`t3a.xlarge`)
- EBS volume for the worker

There should be **no NAT Gateway**, no RDS, no MSK, and no managed Grafana.

## 5. Deploy the AWS foundation

```bash
./scripts/deploy.sh
```

This applies Terraform, configures kubectl, installs Cilium in AWS ENI mode,
installs Argo CD, renders the Kyverno IRSA role, and sets the GitHub Actions
`AWS_ROLE_ARN` repository variable.

## 6. Push the project so CI can build/sign the application

```bash
git add .
git commit -m "Bootstrap AWS Leviathan"
git push
```

Wait for the GitHub Actions workflow **Build, Push, Keyless Sign** to succeed.
It builds the vote/result/worker images, pushes them to ECR, and signs their
immutable digests with Cosign using GitHub OIDC.

## 7. Pin signed image references and enable GitOps

```bash
./scripts/render-demo-images.sh
git add gitops/demo-app/base/app.yaml
git commit -m "Pin signed ECR images"
git push
kubectl apply -f gitops/bootstrap/root-app.yaml
```

Then watch Argo CD:

```bash
kubectl -n argocd get applications -w
```

## 8. Validate

```bash
./scripts/verify.sh
./scripts/demo.sh
```

The intended Friday MVP demonstrates:

1. GitOps desired-state management with Argo CD.
2. Signed-image admission enforcement with Kyverno + Cosign.
3. Cilium network microsegmentation.
4. Istio STRICT mTLS.
5. Falco runtime detection.
6. Honeytoken/deception detection.
7. Falco event forwarding to Kafka.
8. Neo4j, Vault, n8n and Grafana as the intelligence/automation/visibility layer.

Spark is intentionally an on-demand job in this budget build. The final persistent
Kafka -> Spark -> Neo4j and automatic n8n quarantine wiring should be completed and
tested only after the core cluster is healthy.

## 9. Destroy after the demo

```bash
./scripts/destroy.sh
```

Do not leave the EKS cluster/worker running unnecessarily when working under a
limited AWS credit balance.
