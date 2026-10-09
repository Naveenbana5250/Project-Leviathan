#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. Cilium network policy test ==="
echo "Attempting direct frontend -> database connection. This should be blocked once policies are active."
VOTE_POD="$(kubectl -n leviathan get pod -l app=vote -o jsonpath='{.items[0].metadata.name}')"
kubectl -n leviathan exec "$VOTE_POD" -c vote -- python -c 'import socket; s=socket.create_connection(("db",5432),3); s.close()' && \
  echo "WARNING: connection succeeded" || echo "PASS: direct vote -> DB connection blocked (or timed out)"

echo
echo "=== 2. Honeytoken ==="
kubectl -n leviathan run attacker-demo --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://honeytoken:8080/sensitive-data || true
kubectl -n leviathan logs deploy/honeytoken --tail=20

echo
echo "=== 3. Falco runtime signal ==="
echo "Run an interactive shell in a demo pod and inspect Falco logs:"
echo "  kubectl -n leviathan exec -it deploy/vote -c vote -- sh"
echo "  kubectl -n falco logs -l app.kubernetes.io/name=falco --tail=100 | grep -i shell"
