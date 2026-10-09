# Pomerium (optional)

Pomerium is intentionally not part of the first automatic sync because you do not own
a domain and OAuth redirect URLs must be configured correctly.

Install it only after the core platform is healthy. For the final demo, local port-forward
access is sufficient for Argo CD, Grafana, Neo4j, Vault and n8n.

When you later add a domain/GitHub OAuth app, create an Argo CD Application pointing at
the Pomerium Helm chart and store OAuth credentials in a Kubernetes Secret (never Git).
