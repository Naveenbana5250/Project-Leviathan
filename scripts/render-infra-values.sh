#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"
KYVERNO_APP="$ROOT/gitops/apps/10-kyverno.yaml"

KYVERNO_ROLE_ARN="$(terraform -chdir="$TF" output -raw kyverno_ecr_role_arn)"

python3 - "$KYVERNO_APP" "$KYVERNO_ROLE_ARN" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
role = sys.argv[2]
s = p.read_text()
s = s.replace("REPLACE_KYVERNO_ROLE_ARN", role)
s = re.sub(
    r"eks\.amazonaws\.com/role-arn: arn:aws:iam::[0-9]+:role/leviathan-kyverno-ecr",
    f"eks.amazonaws.com/role-arn: {role}",
    s,
)
p.write_text(s)
print(f"Rendered Kyverno IRSA role into {p}")
PY
