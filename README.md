# Project Leviathan — AWS EKS Edition

**Kubernetes-native Zero Trust security and automated defense platform**

This repository is the AWS/EKS rebuild of the earlier on-premises Leviathan lab.
The design intentionally removes multi-region DR and optimizes for a short-lived,
low-cost demonstration in **AWS Mumbai (`ap-south-1`)**.

## What one command does

```bash
./scripts/deploy.sh
```

The script:

1. Runs Terraform to create the VPC, EKS cluster, one low-cost worker, ECR repositories,
   and GitHub Actions OIDC IAM role.
2. Configures `kubectl`.
3. Replaces the EKS `aws-node` datapath with Cilium ENI mode.
4. Installs Argo CD.
5. Writes the GitHub Actions role ARN into a GitHub repository variable.

The GitOps applications are then deployed through Argo CD after the first ECR images
are built and keyless-signed by GitHub Actions.

## Architecture

```text
Developer
   |
   v
GitHub --------------------------+
   |                             |
   | GitOps                      | GitHub Actions OIDC
   v                             v
Argo CD                    Build -> ECR -> Cosign
   |                             |
   +-------------+---------------+
                 v
              AWS EKS
                 |
      +----------+----------+
      |          |          |
   Kyverno     Cilium     Istio
 policy/sign   network     mTLS
      |          |          |
      +----------+----------+
                 |
            App workloads
                 |
      +----------+----------+
      |                     |
    Falco               Honeytoken
      |                     |
      +----------+----------+
                 |
               Kafka
                 |
              Spark*
                 |
              Neo4j
                 |
               n8n
                 |
             Response

*Spark is on-demand in this budget build.
```

## Cost-first design

- One EKS cluster
- One `t3a.xlarge` managed worker by default
- Two AZs, single AWS region
- Public subnets
- **No NAT Gateway**
- No AWS-managed Kafka/Grafana/database services
- Short Prometheus retention
- Apache Kafka single combined broker/controller using the official Apache image
- Neo4j Community single instance
- Vault standalone
- Spark on-demand

This is a lab architecture, not a production landing zone.

## Prerequisites

Already expected on the Mac:

```bash
aws --version
terraform version
kubectl version --client
helm version
gh --version
```

Expected environment:

```bash
export AWS_PROFILE=leviathan-admin
export AWS_REGION=ap-south-1
```

Verify:

```bash
aws sts get-caller-identity
gh auth status
```

## First deployment

From the repository root, create the local variables file and make a saved plan first:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
./scripts/plan.sh
```

Review the Terraform plan carefully. It should show one EKS cluster, one managed worker,
three ECR repositories, IAM/OIDC roles and the dedicated VPC. If it looks correct:

```bash
./scripts/deploy.sh
```

`deploy.sh` applies the reviewed plan, configures `kubectl`, replaces the VPC CNI datapath
with Cilium ENI mode, installs Argo CD, renders the Kyverno IRSA ARN, and creates the
GitHub repository variable used by Actions.

Then commit and push the generated repository content:

```bash
git add .
git commit -m "Bootstrap AWS Leviathan"
git push
```

The `Build, Push, Keyless Sign` GitHub Action creates the three voting-app images in ECR
and signs each immutable digest using GitHub OIDC / Sigstore Cosign.

After the workflow succeeds:

```bash
./scripts/render-demo-images.sh
git add gitops/demo-app/base/app.yaml
git commit -m "Pin signed ECR images"
git push
kubectl apply -f gitops/bootstrap/root-app.yaml
```

## Access dashboards without a domain

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
kubectl -n neo4j port-forward svc/neo4j 7474:7474
kubectl -n n8n port-forward svc/n8n 5678:5678
```

Pomerium is included as an optional future layer because a clean Pomerium deployment
needs a stable domain and OAuth callback URL. It does not block the Friday demo.
Chaos Mesh is also kept optional in this low-memory starter and should be enabled only after the core stack is healthy.

## Destroy immediately after the demo

```bash
./scripts/destroy.sh
```

Then verify EKS, EC2, EBS, Elastic Load Balancers and public IPv4 resources are gone.

## What is automatic vs. still integration work

The package automates the AWS/EKS foundation, Cilium bootstrap, Argo CD bootstrap, ECR,
GitHub OIDC, GitOps manifests, signed-image CI/CD, and the main security services. The
first signed application images require one bootstrap push because the GitHub OIDC IAM
role does not exist until Terraform creates it.

For the Friday MVP, Falco is configured to forward alerts to the `falco-alerts` Kafka topic.
Spark is intentionally on-demand to save memory. The final Spark -> Neo4j enrichment and
fully imported n8n quarantine workflow remain integration steps after the platform is healthy;
the repository does not falsely claim those two links are complete before they are tested.

## Security notes

- No real AWS access keys, GitHub tokens, kubeconfigs, Terraform state or OAuth secrets are
  stored in this repository.
- The fake AWS credential in the honeytoken manifest is deliberately non-valid decoy data.
- The demo application retains non-sensitive demo-only database credentials from the upstream
  voting sample. Replace them with Vault-backed values if this moves beyond a short-lived lab.
- `public_access_cidrs = ["0.0.0.0/0"]` is convenient for first bootstrap but should be
  narrowed to your current public IP `/32` once connectivity is confirmed.
