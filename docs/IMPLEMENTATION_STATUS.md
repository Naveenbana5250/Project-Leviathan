# AWS Leviathan implementation status

## Automated in this starter

- AWS VPC in Mumbai across two AZs.
- EKS control plane and one managed worker node.
- ECR repositories for vote, result and worker.
- GitHub Actions -> AWS authentication with OIDC (no AWS key stored in GitHub).
- GitHub Actions build/push/keyless-Cosign-sign/verify flow.
- Cilium replacement of the VPC CNI datapath using AWS ENI mode.
- Argo CD bootstrap and app-of-apps GitOps layout.
- Kyverno admission controller with ECR read IRSA permissions.
- Kyverno keyless image verification policy for Leviathan ECR images.
- Istio base/control-plane and STRICT mTLS policy.
- Falco runtime security with Falcosidekick -> Kafka output.
- Single-node Apache Kafka KRaft deployment using the official Apache image.
- Honeytoken HTTP service and deliberately invalid AWS/database decoys.
- Neo4j Community single-node deployment.
- Vault standalone deployment.
- n8n deployment.
- Prometheus/Grafana monitoring.
- Reused vote/worker/result demo workload from the older Leviathan project.
- Cilium allow-list policies for the demo workload.
- Terraform destroy helper and post-destroy checks.

## Intentionally lightweight / staged

- Spark runs as an on-demand job instead of a resident Spark cluster.
- Neo4j is non-HA and uses ephemeral storage for the short demo.
- Kafka is a single broker/controller and uses ephemeral storage.
- Vault is standalone and non-persistent in the starter.
- Grafana/Prometheus use short-lived demo storage/retention.
- Pomerium is not part of the automatic core deployment because there is no stable
  domain/OAuth callback URL yet.

## Integration still to prove before calling the complete end-to-end pipeline finished

- Persistent Kafka -> Spark consumption of real Falco/honeytoken events.
- Spark enrichment writes into the Neo4j graph.
- n8n automatically consumes the final event/context format and performs the chosen
  Cilium-based pod quarantine action.
- Final Grafana panels for those end-to-end security outcomes.

These gaps are documented deliberately. The starter does not claim a security control
works until it has been validated in the live EKS environment.
