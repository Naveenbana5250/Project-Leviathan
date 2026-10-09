# Old ZIP analysis -> AWS migration decisions

The supplied older repository contained 103 archived paths and showed a functional
single-VM/kind version of Leviathan. The new edition reuses the pieces that remain
portable and replaces infrastructure-specific pieces.

## Reused concepts/code

- Voting application: vote, worker, result, Redis and PostgreSQL.
- Argo CD GitOps / app-of-apps model.
- Cilium microsegmentation concept.
- Kyverno policy enforcement.
- Cosign build-sign-verify CI/CD pattern.
- Falco runtime detection.
- Honeytoken HTTP service and decoy credential concept.
- Kafka event streaming (new build uses the official Apache Kafka image rather than the post-2025 Bitnami catalog).
- Neo4j relationship / attack-path store.
- Vault, Grafana/Prometheus, n8n and Pomerium roles.

## Replaced for AWS

- kind cluster -> Amazon EKS.
- MetalLB / NodePort exposure -> local port-forward for the demo.
- Docker Hub build pipeline -> Amazon ECR.
- stored Cosign private key -> GitHub OIDC keyless Cosign signing.
- kubeconfig GitHub secret -> AWS GitHub OIDC role.
- local three-node kind topology -> one EKS managed worker node initially.
- single-VM network setup -> AWS VPC + two public subnets, no NAT Gateway.
- old Cilium local setup -> Cilium AWS ENI mode.
- old Bitnami-style Kafka deployment -> single-node official Apache Kafka KRaft deployment.

## Removed from scope

- Multi-region.
- AWS Transit Gateway.
- Cross-region disaster recovery.
- Regional failover/RTO target.

## Sanitized / not copied

The old ZIP contains files named like secrets/credentials, including decoy AWS credentials,
database passwords, fake SSH keys, Stripe decoys, Slack config and Pomerium shared/cookie
secrets. None of those values are copied into the new repository.

The new repository must never contain:
- real AWS access keys,
- `~/.aws/credentials`,
- Terraform state,
- GitHub tokens,
- OAuth client secrets,
- Vault unseal/root tokens.

## Known starter limitations

- Pomerium is optional until a domain/OAuth callback URL exists.
- Spark is included as an on-demand ETL job to save RAM; the full Kafka -> Spark -> Neo4j
  production pipeline is an integration task, not a permanent resident Spark cluster.
- n8n is deployed, but the final quarantine playbook still needs to be wired to the exact
  Falco/Kafka event schema during integration.
- Public-subnet worker placement is chosen only to avoid NAT Gateway cost in a short-lived lab.
