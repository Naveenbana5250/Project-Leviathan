#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"
FILE="$ROOT/gitops/demo-app/base/app.yaml"

ACCOUNT="$(terraform -chdir="$TF" output -raw aws_account_id)"
REGION="${AWS_REGION:-ap-south-1}"
SHA="$(git rev-parse HEAD)"

VOTE="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/leviathan-vote:${SHA}"
RESULT="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/leviathan-result:${SHA}"
WORKER="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/leviathan-worker:${SHA}"

python3 - "$FILE" "$VOTE" "$RESULT" "$WORKER" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace("REPLACE_VOTE_IMAGE", sys.argv[2])
s = s.replace("REPLACE_RESULT_IMAGE", sys.argv[3])
s = s.replace("REPLACE_WORKER_IMAGE", sys.argv[4])
p.write_text(s)
print("Updated", p)
PY

echo "Pinned demo manifests to commit tag: $SHA"
echo "Commit and push the manifest update, then Argo CD can deploy it."
