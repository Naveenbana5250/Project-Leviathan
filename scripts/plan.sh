#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"
export AWS_PROFILE="${AWS_PROFILE:-leviathan-admin}"
export AWS_REGION="${AWS_REGION:-ap-south-1}"
"$ROOT/scripts/preflight.sh"
terraform -chdir="$TF" init
terraform -chdir="$TF" fmt -check
terraform -chdir="$TF" validate
terraform -chdir="$TF" plan -out=leviathan.tfplan
printf '\nSaved plan: %s/leviathan.tfplan\n' "$TF"
printf 'Review it above. If it looks correct, run ./scripts/deploy.sh\n'
